#!/usr/bin/env bash
#
# Sweep every catalog component through the Demo app, in one or both modes:
#
#   --capture   render each component to the Figma-import JSON and push it to the local
#               serve (populates the plugin's Catalog list). Requires the serve running.
#   --preview   screenshot each component — and each tweak variant, light + dark — to PNGs
#               for visual review.
#
# With no mode flag it does both. Component ids come from the app's own registry dump
# (-PinwheelManifest), so the sweep stays in sync as components change — no source grepping.
#
# Usage:
#   Scripts/sweep.sh                       # build, then capture AND preview
#   Scripts/sweep.sh --capture             # capture only
#   Scripts/sweep.sh --preview             # preview only
#   Scripts/sweep.sh --capture --no-build  # reuse the last build (faster)
#
# Env overrides:
#   PINWHEEL_SIM="Pinwheel Sweep"          # name of the dedicated sweep simulator (created if missing)
#   PINWHEEL_SERVE="http://localhost:8787"
#   PINWHEEL_PREVIEW_OUT=/tmp/...          # preview PNG output directory
#
# Serve (for --capture):  cd figma-plugin && npm run serve

set -euo pipefail

readonly BUNDLE_ID="com.nordser.pinwheel"
readonly SCHEME="Demo"
readonly SERVE="${PINWHEEL_SERVE:-http://localhost:8787}"
readonly PREVIEW_OUT="${PINWHEEL_PREVIEW_OUT:-/tmp/pinwheel-previews}"
readonly DERIVED="/tmp/pinwheel-sweep-dd"
readonly BUILD_LOG="/tmp/pinwheel-sweep-build.log"

UDID=""
CONTAINER=""
ONLY=""

err() { echo "sweep: $*" >&2; }
die() { err "$*"; exit 1; }

usage() {
  cat >&2 <<'EOF'
Usage: Scripts/sweep.sh [--capture] [--preview] [--no-build] [--only=<id>]
  --capture    render each component to Figma JSON and push it to the serve
  --preview    screenshot each component (+ tweak variants, light + dark) to PNGs
  --no-build   reuse the last build
  --only=<id>  capture just one component (e.g. swiftui-numbers) without clearing the
               rest of the catalog — a fast spot-check; still resolves the booted sim
  (no mode)    do both
EOF
}

cleanup() {
  [[ -n "${UDID}" ]] && xcrun simctl ui "${UDID}" appearance light >/dev/null 2>&1 || true
}

# Resolve (or create) a persistent, dedicated sweep simulator by UDID — never "whichever device is
# booted", which silently grabs the wrong sim and captures/builds against it. Reusing one named sim keeps
# it warm across runs. Created on the newest available iOS runtime + newest iPhone (a capability, not a
# pinned model, so it survives runner/Xcode bumps). Override the name with PINWHEEL_SIM.
resolve_udid() {
  local name="${PINWHEEL_SIM:-Pinwheel Sweep}" udid
  udid="$(xcrun simctl list devices available | grep -m1 "    ${name} (" | grep -oE '[0-9A-F-]{36}' || true)"
  if [[ -z "${udid}" ]]; then
    err "creating dedicated sweep simulator '${name}' ..."
    local pair runtime device_type
    pair="$(xcrun simctl list -j runtimes | python3 -c "
import json, re, sys
runtimes = [r for r in json.load(sys.stdin)['runtimes'] if r['platform'] == 'iOS' and r['isAvailable']]
runtime = sorted(runtimes, key=lambda r: [int(x) for x in r['version'].split('.')])[-1]
phones = [d for d in runtime['supportedDeviceTypes'] if 'iPhone' in d['identifier']]
def newest(device):
    match = re.search(r'iPhone (\d+)', device['name'])
    return (int(match.group(1)) if match else 0, -len(device['name']))
print(runtime['identifier']); print(sorted(phones, key=newest)[-1]['identifier'])
")"
    runtime="$(head -1 <<<"${pair}")"
    device_type="$(tail -1 <<<"${pair}")"
    [[ -n "${runtime}" && -n "${device_type}" ]] || die "no available iOS runtime/iPhone to create '${name}'"
    udid="$(xcrun simctl create "${name}" "${device_type}" "${runtime}")"
  fi
  xcrun simctl bootstatus "${udid}" -b >/dev/null 2>&1 || true
  echo "${udid}"
}

build_and_install() {
  local no_build="$1" app
  if [[ "${no_build}" != "true" ]]; then
    err "building ${SCHEME} ..."
    xcodebuild -scheme "${SCHEME}" -destination "id=${UDID}" -derivedDataPath "${DERIVED}" \
      CODE_SIGNING_ALLOWED=NO build >"${BUILD_LOG}" 2>&1 \
      || { tail -40 "${BUILD_LOG}"; die "build failed — see ${BUILD_LOG}"; }
  fi
  app="$(find "${DERIVED}/Build/Products" -maxdepth 3 -name "${SCHEME}.app" 2>/dev/null | head -1 || true)"
  [[ -n "${app}" ]] || die "no built ${SCHEME}.app — run without --no-build first"
  xcrun simctl install "${UDID}" "${app}"
}

dump_ids() {
  local manifest="${CONTAINER}/Documents/pinwheel-catalog.json" i
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
  rm -f "${manifest}"
  xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelManifest >/dev/null 2>&1
  for ((i = 0; i < 20; i++)); do [[ -f "${manifest}" ]] && break; sleep 0.5; done
  [[ -f "${manifest}" ]] || die "app did not dump ${manifest}"
  python3 -c "import json; print('\n'.join(item['id'] for item in json.load(open('${manifest}'))))"
}

capture_round() {
  local -a ids=("$@")
  local id
  for id in "${ids[@]}"; do
    xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
    xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelCapture "${id}" >/dev/null 2>&1
    sleep 3
    echo "  ok: ${id}"
  done
}

run_capture() {
  local -a ids=("$@")
  local count light_dir="/tmp/pinwheel-sweep-light"
  curl -sf -o /dev/null "${SERVE}/manifest.json" \
    || die "--capture needs the serve at ${SERVE} — run 'npm run serve' in figma-plugin/"
  # A UIKit control (switch/segmented/slider/stepper/progress/datepicker) only paints in the SIM's appearance — no in-app override repaints it — so sweep twice, sim light then dark.
  if [[ -z "${ONLY}" ]]; then
    err "clearing previous catalog on serve ..."
    curl -sf -X DELETE "${SERVE}/catalog" >/dev/null
    err "rebooting simulator for a clean render server ..."
    xcrun simctl shutdown "${UDID}" >/dev/null 2>&1 || true
    xcrun simctl boot "${UDID}" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "${UDID}" -b >/dev/null 2>&1 || true
  fi

  rm -rf "${light_dir}"; mkdir -p "${light_dir}"
  err "capturing ${#ids[@]} components (light) ..."
  xcrun simctl ui "${UDID}" appearance light >/dev/null 2>&1 || true
  capture_round "${ids[@]}"
  # Save every light document before the dark round overwrites it on the serve.
  python3 - "${SERVE}" "${light_dir}" "${ids[@]}" <<'PY'
import json, sys, os, urllib.request
serve, out, captured = sys.argv[1], sys.argv[2], set(sys.argv[3:])
items = json.load(urllib.request.urlopen(serve + '/manifest.json'))['items']
for item in items:
    if item['id'] not in captured:
        continue
    data = urllib.request.urlopen(serve + '/' + item['file']).read()
    open(os.path.join(out, item['id'] + '.json'), 'wb').write(data)
PY

  err "capturing ${#ids[@]} components (dark) ..."
  xcrun simctl ui "${UDID}" appearance dark >/dev/null 2>&1 || true
  capture_round "${ids[@]}"
  err "merging light + dark ..."
  python3 - "${SERVE}" "${light_dir}" "${ids[@]}" <<'PY'
import json, sys, os, urllib.request
serve, saved, captured = sys.argv[1], sys.argv[2], set(sys.argv[3:])
def graft(light, dark):
    if dark is not None:
        if light.get('image') is not None: light['imageDark'] = dark.get('image')
        if light.get('fill') is not None: light['fillDark'] = dark.get('fill')
    darkKids = (dark or {}).get('children') or []
    for i, child in enumerate(light.get('children') or []):
        graft(child, darkKids[i] if i < len(darkKids) else None)
items = json.load(urllib.request.urlopen(serve + '/manifest.json'))['items']
for item in items:
    if item['id'] not in captured:
        continue
    path = os.path.join(saved, item['id'] + '.json')
    if not os.path.exists(path):
        continue
    light = json.load(open(path))
    dark = json.load(urllib.request.urlopen(serve + '/' + item['file']))
    graft(light['document']['root'], dark['document']['root'])
    body = json.dumps({k: light[k] for k in ('app', 'id', 'title', 'section', 'tags', 'version', 'document')}).encode()
    req = urllib.request.Request(serve + '/catalog', data=body, headers={'Content-Type': 'application/json'}, method='POST')
    urllib.request.urlopen(req).read()
    print('  merged: ' + item['id'])
PY

  xcrun simctl ui "${UDID}" appearance light >/dev/null 2>&1 || true
  count="$(curl -sf "${SERVE}/manifest.json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['items']))")"
  err "captured ${count} components (light + dark merged) — open the plugin's Catalog to import any."
}

run_preview() {
  local -a ids=("$@")
  local light_out="${PREVIEW_OUT}" dark_out="${PREVIEW_OUT}/dark"
  local tweaks_file="${CONTAINER}/Documents/pinwheel-preview-tweaks.txt"
  local appearance id tweak tweak_list dest tweaks_dest
  mkdir -p "${light_out}" "${dark_out}" "${light_out}/tweaks" "${dark_out}/tweaks"
  rm -f "${light_out}"/*.png "${dark_out}"/*.png "${light_out}"/tweaks/*.png "${dark_out}"/tweaks/*.png

  snapshot() {
    local out_dir="$1" id="$2" name="$3" tweak="${4:-}"
    xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
    if [[ -n "${tweak}" ]]; then
      xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelPreview "${id}" -PinwheelPreviewTweak "${tweak}" >/dev/null 2>&1
    else
      xcrun simctl launch "${UDID}" "${BUNDLE_ID}" -PinwheelPreview "${id}" >/dev/null 2>&1
    fi
    sleep 2
    xcrun simctl io "${UDID}" screenshot "${out_dir}/${name}.png" >/dev/null 2>&1
  }

  for appearance in light dark; do
    xcrun simctl ui "${UDID}" appearance "${appearance}" >/dev/null 2>&1 || true
    if [[ "${appearance}" == "dark" ]]; then dest="${dark_out}"; else dest="${light_out}"; fi
    tweaks_dest="${dest}/tweaks"
    err "snapshotting ${#ids[@]} components (${appearance}) → ${dest} (tweaks in ./tweaks) ..."
    for id in "${ids[@]}"; do
      rm -f "${tweaks_file}"
      snapshot "${dest}" "${id}" "${id}"
      echo "  ok: ${id}"
      # A variant launch re-dumps the tweaks file, so read it into memory before looping.
      if [[ -f "${tweaks_file}" ]]; then
        tweak_list="$(cat "${tweaks_file}")"
        while IFS= read -r tweak; do
          [[ -n "${tweak}" ]] || continue
          snapshot "${tweaks_dest}" "${id}" "${id}__$(tr '[:upper:]' '[:lower:]' <<<"${tweak}" | tr ' ' '-')" "${tweak}"
          echo "    ok: ${id} / ${tweak}"
        done <<<"${tweak_list}"
      fi
    done
  done

  err "previews — light: ${light_out}  |  dark: ${dark_out}  (tweak variants in each ./tweaks)"
  open "${PREVIEW_OUT}" 2>/dev/null || true
}

main() {
  local do_capture=false do_preview=false no_build=false arg
  for arg in "$@"; do
    case "${arg}" in
      --capture) do_capture=true ;;
      --preview) do_preview=true ;;
      --no-build) no_build=true ;;
      --only=*) ONLY="${arg#--only=}"; do_capture=true ;;
      -h|--help) usage; return 0 ;;
      *) usage; die "unknown argument '${arg}'" ;;
    esac
  done
  if ! "${do_capture}" && ! "${do_preview}"; then
    do_capture=true
    do_preview=true
  fi

  cd "$(dirname "$0")/.."
  trap cleanup EXIT

  UDID="$(resolve_udid)"
  build_and_install "${no_build}"
  CONTAINER="$(xcrun simctl get_app_container "${UDID}" "${BUNDLE_ID}" data)"

  local -a ids=()
  local line
  while IFS= read -r line; do
    [[ -n "${line}" ]] && ids+=("${line}")
  done < <(dump_ids)
  [[ "${#ids[@]}" -gt 0 ]] || die "no component ids in the catalog skeleton"

  if [[ -n "${ONLY}" ]]; then
    printf '%s\n' "${ids[@]}" | grep -qx "${ONLY}" || die "no component '${ONLY}' in the catalog (ids: ${ids[*]})"
    ids=("${ONLY}")
  fi

  if "${do_capture}"; then run_capture "${ids[@]}"; fi
  if "${do_preview}"; then run_preview "${ids[@]}"; fi
}

main "$@"
