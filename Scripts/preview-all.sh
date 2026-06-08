#!/usr/bin/env bash
#
# Snapshot every catalog component to a PNG for quick visual review.
#
# Builds + installs the Demo once, then deep-links the app to each component id
# (via the `-PinwheelPreview <id>` launch arg) and screenshots it. Ids are read
# straight from the catalog registry, so this stays in sync as components change.
#
# Usage:
#   Scripts/preview-all.sh              # build, then snapshot every component
#   Scripts/preview-all.sh --no-build   # reuse the last build (faster)
#
# Env overrides:
#   PINWHEEL_SIM="iPhone 17 Pro"        # simulator device name
#   PINWHEEL_PREVIEW_OUT=/tmp/...       # output directory
#
# Note: components render in their DEFAULT state - some (e.g. the UIKit StateView,
# which defaults to .loaded) are intentionally blank until you drive a tweak.

set -euo pipefail

BUNDLE_ID="com.nordser.pinwheel"
SCHEME="Demo"
DEVICE="${PINWHEEL_SIM:-iPhone 17 Pro}"
OUT="${PINWHEEL_PREVIEW_OUT:-/tmp/pinwheel-previews}"
DERIVED="/tmp/pinwheel-preview-dd"

cd "$(dirname "$0")/.."
REGISTRY="Demo/SwiftUIExamples/DemoPinwheelSections.swift"

mkdir -p "${OUT}"
rm -f "${OUT}"/*.png

echo "Booting ${DEVICE} ..."
UDID="$(xcrun simctl list devices available | grep -m1 "${DEVICE} (" | grep -oE '[0-9A-F-]{36}' || true)"
[ -n "${UDID}" ] || { echo "ERROR: no available simulator named '${DEVICE}'"; exit 1; }
xcrun simctl boot "${UDID}" 2>/dev/null || true
xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || true

if [ "${1:-}" != "--no-build" ]; then
  echo "Building ${SCHEME} ..."
  xcodebuild -scheme "${SCHEME}" -destination "id=${UDID}" -derivedDataPath "${DERIVED}" build >/dev/null
fi

APP="$(find "${DERIVED}/Build/Products" -name "${SCHEME}.app" -maxdepth 3 2>/dev/null | head -1 || true)"
[ -n "${APP}" ] || { echo "ERROR: no built ${SCHEME}.app - run without --no-build first"; exit 1; }
xcrun simctl install "${UDID}" "${APP}"

# Component ids come from PinwheelItem(... id: "...") entries in the registry.
IDS="$(grep 'PinwheelItem' "${REGISTRY}" | grep -oE 'id: "[^"]+"' | sed -E 's/id: "([^"]+)"/\1/')"
[ -n "${IDS}" ] || { echo "ERROR: found no component ids in ${REGISTRY}"; exit 1; }

echo "Snapshotting components ..."
for ID in ${IDS}; do
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
  xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelPreview "${ID}" >/dev/null 2>&1
  sleep 2
  xcrun simctl io "${UDID}" screenshot "${OUT}/${ID}.png" >/dev/null 2>&1
  echo "  ok: ${ID}"
done

# Optional contact sheet if ImageMagick is installed.
if command -v montage >/dev/null 2>&1; then
  montage "${OUT}"/*.png -tile 5x -geometry 240x+6+6 -title "Pinwheel components" "${OUT}/_contact-sheet.png" 2>/dev/null \
    && echo "Contact sheet: ${OUT}/_contact-sheet.png"
fi

echo "Done. PNGs in: ${OUT}"
open "${OUT}" 2>/dev/null || true
