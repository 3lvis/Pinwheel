---
name: xcode-mcp
description: Build, render previews, and run tests for this iOS project via the Xcode MCP (Apple's `xcrun mcpbridge`) — the PREFERRED way to iterate here, faster than shelling out to xcodebuild. Use whenever asked to build, run, preview/screenshot, or test the Pinwheel Demo or package, or to iterate on a component. Also covers the one-time MCP setup and the xcodebuild/simctl fallback when the MCP is unavailable.
---

# Iterating on this project with the Xcode MCP

Apple's `xcrun mcpbridge` (Xcode 26.3+) bridges into the **running** Xcode over XPC and exposes ~20 `mcp__xcode__*` tools. **Prefer it over `xcodebuild`/`simctl`** — `BuildProject` returns in ~3s vs ~30s for a cold `xcodebuild`, `RenderPreview` snapshots a `#Preview` with no simulator launch, and `RunSomeTests` runs XCUITests with structured results.

Every tool takes `tabIdentifier`. For this repo it is **`windowtab1`** (`Demo.xcodeproj`). Confirm with `XcodeListWindows` if unsure.

## Setup (one-time) — and the non-obvious gotcha

The tools only appear in the session's tool registry when **all** of these held **at session start**:
1. Xcode is **open with `Demo.xcodeproj`** (the bridge attaches to a live Xcode PID — no Xcode, no tools).
2. **Xcode ▸ Settings ▸ Intelligence ▸ Model Context Protocol ▸ "Xcode Tools" is ON** (the *Permissions* subsection also governs which commands/tools the assistant may use).
3. The server is registered: `claude mcp add --transport stdio xcode -- xcrun mcpbridge` (verify with `claude mcp list` → `xcode: xcrun mcpbridge - ✓ Connected`).

**Gotcha that cost us real time:** enabling the toggle (or opening Xcode) *mid-session* is not enough. `claude mcp list` will show "Connected" and `ToolSearch` will still find nothing, because the deferred-tool index is enumerated at **session start**. Fix: **quit and restart the Claude session** with Xcode already open and the toggle on. On the next launch the `mcp__xcode__*` tools register and `ToolSearch select:mcp__xcode__RunSomeTests,...` resolves them.

If you can't restart (or no MCP), use the **Fallback** section below — it produces the same results, just slower.

## The iterate loop

1. **Build:** `BuildProject(tabIdentifier)` → `{buildResult, errors, fullLogPath, elapsedTime}`. Fast; run it after every edit.
2. **Diagnose failures:** `GetBuildLog(tabIdentifier, severity: "warning"|"error", pattern?, glob?)` for the build task's issues, or `XcodeListNavigatorIssues(tabIdentifier, severity?)` for what Xcode's Issue Navigator shows (incl. package-resolution problems). Aim for zero warnings.
3. **Visual check (no simulator):** `RenderPreview(tabIdentifier, sourceFilePath, previewDefinitionIndexInFile?, previewVariantOverrides?)` → returns `previewSnapshotPath` (a PNG — open it with Read) plus `supportedPreviewVariantOverrides` (Color Scheme, Dynamic Type, Orientation). Re-render dark mode / accessibility sizes via e.g. `previewVariantOverrides: {"Color Scheme": "Dark Appearance"}`.
4. **Tests:** `GetTestList(tabIdentifier)` → identifiers; `RunSomeTests(tabIdentifier, tests:[{targetName, testIdentifier}])` or `RunAllTests(tabIdentifier)` → `{counts, results:[{state, errorMessages}], fullConsoleLogsPath}`.

## Tool catalogue (verified this repo)

| Tool | Use | Key args | Returns |
|---|---|---|---|
| `XcodeListWindows` | Find the tab id | — | `tabIdentifier` (→ `windowtab1`) |
| `BuildProject` | Compile | `tabIdentifier` | buildResult, errors[], fullLogPath |
| `GetBuildLog` | Filter last build's issues | `tabIdentifier`, severity, pattern, glob | log entries |
| `XcodeListNavigatorIssues` | Issue-navigator state | `tabIdentifier`, severity, glob, pattern | issues[] |
| `RenderPreview` | Snapshot a `#Preview` | `tabIdentifier`, `sourceFilePath`, previewDefinitionIndexInFile, previewVariantOverrides, timeout | previewSnapshotPath (PNG), supportedPreviewVariantOverrides |
| `GetTestList` | Enumerate tests | `tabIdentifier` | tests[] with `targetName` + `identifier` |
| `RunSomeTests` | Run specific tests | `tabIdentifier`, `tests:[{targetName, testIdentifier}]` | counts, per-test results, logs |
| `RunAllTests` | Run the active test plan | `tabIdentifier` | same |
| `DocumentationSearch` | Apple docs (semantic) | `query`, frameworks? | ranked doc excerpts |
| `ExecuteSnippet` | Run a Swift snippet in a file's context (print output) | `tabIdentifier`, `sourceFilePath`, `codeSnippet`, `purpose` | console output |
| `XcodeRead`/`XcodeWrite`/`XcodeUpdate`/`XcodeGrep`/`XcodeGlob`/`XcodeLS`/`XcodeMV`/`XcodeRM`/`XcodeMakeDir`/`XcodeGetCurrentFile`/`XcodeRefreshCodeIssuesInFile` | File ops inside the project organization | vary | — |

`sourceFilePath` is project-relative within the Xcode organization. Refer to files by **name + role** and resolve the current path with `XcodeGlob`/`XcodeGrep` at call time — folders get reorganized, so hard-coded paths in docs rot (e.g. find the catalog registry with `XcodeGlob "**/DemoPinwheelSections.swift"`).

## How RenderPreview targets a `#Preview`

`RenderPreview` is NOT a "render any view" call — it drives Xcode's real preview pipeline (the canvas engine) against a **preview definition that must already exist in `sourceFilePath`**: a `#Preview { … }` macro or a `PreviewProvider` struct.

- `previewDefinitionIndexInFile` is the **0-based index of the `#Preview`/`PreviewProvider` in that file**, top to bottom (default `0`). That's how you pick among multiple previews in one file.
- It **builds** the preview, runs it in the preview agent, and returns `previewSnapshotPath` (a PNG — open with Read). **No simulator boot.** The preview must compile, so run `BuildProject`/`GetBuildLog` first if unsure.
- A file with no `#Preview`/`PreviewProvider` → nothing to render → error. There is no raw-expression mode.
- It's a **static snapshot in isolation** — no interaction. For taps/behavior use `RunSomeTests` (XCUITests) or `BuildProject` + `simctl launch -PinwheelPreview <id>`.
- Snapshot variants: pass `previewVariantOverrides` using keys/values from a prior call's `supportedPreviewVariantOverrides`, e.g. `{"Color Scheme": "Dark Appearance"}` or `{"Dynamic Type": "AX 3"}`.

This is exactly why the repo keeps ONE permanent `#Preview` (see below) instead of hand-writing a throwaway per component.

## This repo's iteration shortcuts

- **Render any component without a simulator:** the permanent `#Preview` at the bottom of the catalog registry file (`DemoPinwheelSections.swift`) renders whatever `previewComponentID` points at. Edit that one constant, then `RenderPreview` with that file's project-relative `sourceFilePath` (locate it via `XcodeGlob` if it has moved).
- **Deep-link the running app to one component:** launch arg `-PinwheelPreview <id>` (bare `button` or qualified `components/button`); reads `PinwheelPreview.requestedID`. Bundle id `com.nordser.pinwheel`. Add `-PinwheelPreviewTweak <title>` to land directly on a variant (e.g. the StateView "Failed" state) without tapping. In preview mode the render is captioned with `id · variant`, and the component's tweak titles are dumped to `<dataContainer>/Documents/pinwheel-preview-tweaks.txt`.
- **Snapshot every component + variant:** `Scripts/sweep.sh --preview` builds+installs once, then deep-links each component and each of its tweak variants, writing captioned PNGs to `/tmp/pinwheel-previews`. `--no-build` reuses the last build. (Omit `--preview` to also push the Figma capture; `--capture` for that alone.)
- **Interaction tests (taps):** `StateViewUITests.swift` (in the `DemoUITests` target) is the template — set `app.launchArguments = ["-PinwheelPreview", "<id>"]`, then drive real UI. Accessibility ids on the playground floating controls: `pinwheel.settings` (wrench), `pinwheel.close`. Tweak rows and `PinButton`s are addressable by their visible label (`app.buttons["Failed"]`, `app.buttons["Retry"]`). Run with `RunSomeTests` targeting `DemoUITests`.

## Fallback (no MCP)

Same results via CLI — slower, but headless and reliable:

```sh
SIM=$(xcrun simctl list devices available | grep -m1 "iPhone 17 Pro" | grep -oE '[0-9A-F-]{36}')
# Build
xcodebuild -scheme Demo -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath /tmp/dd build
# UI tests
xcodebuild test -scheme Demo -destination "platform=iOS Simulator,id=$SIM" -only-testing:DemoUITests/StateViewUITests
# Run + screenshot a component (no tap primitive in simctl)
APP=$(find /tmp/dd/Build/Products -name Demo.app -maxdepth 3 | head -1)
xcrun simctl install "$SIM" "$APP"
xcrun simctl launch "$SIM" com.nordser.pinwheel -PinwheelPreview button
xcrun simctl io "$SIM" screenshot /tmp/shot.png
```

## Gotchas

- **MCP needs a running Xcode** on the project; if Xcode closes/crashes, calls fail until it's reopened (then restart the session per the setup gotcha).
- **`simctl` has no tap** — exercise interactions with XCUITests (`RunSomeTests`), not screenshots. (osascript clicking the Simulator works but is imprecise on small targets.)
- **Test-target deployment alignment:** keep `DemoUITests`' `IPHONEOS_DEPLOYMENT_TARGET` ≤ the installed simulator runtime (it's `18.0`, matching the app); a higher value (e.g. 26.5 on a 26.2 sim) makes tests refuse to run.
- Prefer `RunSomeTests` over `RunAllTests` while iterating — `DemoUITests` also has slow template tests (`testLaunchPerformance`).
