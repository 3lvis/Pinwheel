#!/usr/bin/env bash
#
# Snapshot every catalog component - and each of its tweakable variants - to a
# PNG for quick visual review. Each image has the component id (and variant)
# captioned into the render, so the picture is self-describing.
#
# Builds + installs the Demo once, then deep-links the app to each component via
# the `-PinwheelPreview <id>` launch arg. For every component it reads the tweak
# titles the app dumps to its container, and re-launches with
# `-PinwheelPreviewTweak <title>` to capture each variant (e.g. the StateView's
# Loading/Loaded/Empty/Failed). Ids come from the catalog registry, so this
# stays in sync as components change.
#
# Usage:
#   Scripts/preview-all.sh              # build, then snapshot everything
#   Scripts/preview-all.sh --no-build   # reuse the last build (faster)
#
# Env overrides:
#   PINWHEEL_SIM="iPhone 17 Pro"        # simulator device name
#   PINWHEEL_PREVIEW_OUT=/tmp/...       # output directory

set -euo pipefail

BUNDLE_ID="com.nordser.pinwheel"
SCHEME="Demo"
DEVICE="${PINWHEEL_SIM:-iPhone 17 Pro}"
OUT="${PINWHEEL_PREVIEW_OUT:-/tmp/pinwheel-previews}"
DERIVED="/tmp/pinwheel-preview-dd"

cd "$(dirname "$0")/.."
# Locate the registry by name so this survives folder reorganizations.
REGISTRY="$(find Demo -name DemoPinwheelSections.swift -print -quit)"
[ -n "${REGISTRY}" ] || { echo "ERROR: could not find DemoPinwheelSections.swift under Demo/"; exit 1; }

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

# Path where the app dumps the current component's tweak titles.
CONTAINER="$(xcrun simctl get_app_container "${UDID}" "${BUNDLE_ID}" data)"
TWEAKS_FILE="${CONTAINER}/Documents/pinwheel-preview-tweaks.txt"

# Component ids come from PinwheelItem(... id: "...") entries in the registry.
IDS="$(grep 'PinwheelItem' "${REGISTRY}" | grep -oE 'id: "[^"]+"' | sed -E 's/id: "([^"]+)"/\1/')"
[ -n "${IDS}" ] || { echo "ERROR: found no component ids in ${REGISTRY}"; exit 1; }

snapshot() { # <preview-id> <output-name> [tweak-title]
  local id="$1" name="$2" tweak="${3:-}"
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
  if [ -n "${tweak}" ]; then
    xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelPreview "${id}" -PinwheelPreviewTweak "${tweak}" >/dev/null 2>&1
  else
    xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelPreview "${id}" >/dev/null 2>&1
  fi
  sleep 2
  xcrun simctl io "${UDID}" screenshot "${OUT}/${name}.png" >/dev/null 2>&1
}

slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'; }

# Capture each component (and its tweak variants) in both light and dark; dark
# files get a `-dark` suffix. The app re-launches per snapshot, so it picks up the
# current simulator appearance on launch.
for APPEARANCE in light dark; do
  xcrun simctl ui "${UDID}" appearance "${APPEARANCE}" >/dev/null 2>&1 || true
  SUFFIX=""; [ "${APPEARANCE}" = "dark" ] && SUFFIX="-dark"
  echo "Snapshotting components (${APPEARANCE}) ..."
  for ID in ${IDS}; do
    rm -f "${TWEAKS_FILE}"
    snapshot "${ID}" "${ID}${SUFFIX}"      # default state; app dumps this component's tweaks
    echo "  ok: ${ID}${SUFFIX}"

    if [ -f "${TWEAKS_FILE}" ]; then
      # Read into memory first: each variant launch re-dumps this file, so reading
      # straight from it would truncate mid-loop.
      TWEAK_LIST="$(cat "${TWEAKS_FILE}")"
      while IFS= read -r TWEAK; do
        [ -n "${TWEAK}" ] || continue
        snapshot "${ID}" "${ID}__$(slug "${TWEAK}")${SUFFIX}" "${TWEAK}"
        echo "    ok: ${ID} / ${TWEAK} (${APPEARANCE})"
      done <<< "${TWEAK_LIST}"
    fi
  done
done

# Optional contact sheet if ImageMagick is installed.
if command -v montage >/dev/null 2>&1; then
  montage "${OUT}"/*.png -tile 5x -geometry 240x+6+6 -title "Pinwheel components" "${OUT}/_contact-sheet.png" 2>/dev/null \
    && echo "Contact sheet: ${OUT}/_contact-sheet.png"
fi

echo "Done. PNGs in: ${OUT}"
open "${OUT}" 2>/dev/null || true
