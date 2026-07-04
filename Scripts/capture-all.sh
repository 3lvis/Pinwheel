#!/usr/bin/env bash
#
# Capture every catalog component to the local Figma capture serve, so the plugin can list them
# and import any one without relaunching the app per component (the "manifest sweep").
#
# Builds + installs the Demo once, dumps the catalog skeleton via `-PinwheelManifest`, then
# deep-links the app to each id via `-PinwheelCapture <id>`. Each launch renders that item in a
# capture host and pushes its IR (keyed by id, with metadata) to the serve; the serve accumulates
# them into /manifest.json. Ids come from the registry itself (the dumped skeleton), so this stays
# in sync as components change — no source grepping.
#
# Requires the serve running:  (cd ../../web/fonno/frontend && npm run figma:serve)
#
# Usage:
#   Scripts/capture-all.sh              # build, then capture everything
#   Scripts/capture-all.sh --no-build   # reuse the last build (faster)
#
# Env overrides:
#   PINWHEEL_SIM="iPhone 17 Pro"        # simulator device name (else the booted one)
#   PINWHEEL_SERVE="http://localhost:8787"

set -euo pipefail

BUNDLE_ID="com.nordser.pinwheel"
SCHEME="Demo"
SERVE="${PINWHEEL_SERVE:-http://localhost:8787}"
DERIVED="/tmp/pinwheel-capture-dd"

cd "$(dirname "$0")/.."

if ! curl -sf -o /dev/null "${SERVE}/manifest.json"; then
  echo "ERROR: capture serve not reachable at ${SERVE} — run 'npm run figma:serve' in fonno/frontend first"
  exit 1
fi

# Prefer an already-booted sim; else boot the named device.
UDID="$(xcrun simctl list devices | awk -F '[()]' '/Booted/ {print $2; exit}')"
if [ -z "${UDID}" ]; then
  DEVICE="${PINWHEEL_SIM:-iPhone 17 Pro}"
  echo "Booting ${DEVICE} ..."
  UDID="$(xcrun simctl list devices available | grep -m1 "${DEVICE} (" | grep -oE '[0-9A-F-]{36}' || true)"
  [ -n "${UDID}" ] || { echo "ERROR: no available simulator named '${DEVICE}'"; exit 1; }
  xcrun simctl boot "${UDID}" 2>/dev/null || true
  xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || true
fi

if [ "${1:-}" != "--no-build" ]; then
  echo "Building ${SCHEME} ..."
  BUILD_LOG="/tmp/pinwheel-capture-build.log"
  xcodebuild -scheme "${SCHEME}" -destination "id=${UDID}" -derivedDataPath "${DERIVED}" \
    CODE_SIGNING_ALLOWED=NO build >"${BUILD_LOG}" 2>&1 \
    || { echo "ERROR: build failed - see ${BUILD_LOG}"; tail -40 "${BUILD_LOG}"; exit 1; }
fi

APP="$(find "${DERIVED}/Build/Products" -name "${SCHEME}.app" -maxdepth 3 2>/dev/null | head -1 || true)"
[ -n "${APP}" ] || { echo "ERROR: no built ${SCHEME}.app - run without --no-build first"; exit 1; }
xcrun simctl install "${UDID}" "${APP}"

CONTAINER="$(xcrun simctl get_app_container "${UDID}" "${BUNDLE_ID}" data)"
MANIFEST="${CONTAINER}/Documents/pinwheel-catalog.json"

echo "Dumping catalog skeleton ..."
xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
rm -f "${MANIFEST}"
xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelManifest >/dev/null 2>&1
for _ in $(seq 1 20); do [ -f "${MANIFEST}" ] && break; sleep 0.5; done
[ -f "${MANIFEST}" ] || { echo "ERROR: app did not dump ${MANIFEST}"; exit 1; }

IDS="$(python3 -c "import json,sys; print('\n'.join(i['id'] for i in json.load(open('${MANIFEST}'))))")"
[ -n "${IDS}" ] || { echo "ERROR: no ids in catalog skeleton"; exit 1; }

echo "Clearing previous catalog on serve ..."
curl -sf -X DELETE "${SERVE}/catalog" >/dev/null

echo "Capturing components ..."
for ID in ${IDS}; do
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
  xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelCapture "${ID}" >/dev/null 2>&1
  sleep 3   # let the layout pass, any rasterization, and the push complete
  echo "  ok: ${ID}"
done

COUNT="$(curl -sf "${SERVE}/manifest.json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['items']))")"
echo "Done. ${COUNT} components on the serve — open the plugin's Catalog to import any."
