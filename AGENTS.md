# Agent Guidelines

- Treat Pinwheel as a SwiftUI-first package with UIKit compatibility.
- Do not add `import UIKit` to SwiftUI-first views, SwiftUI examples, or SwiftUI API call sites.
- Keep UIKit usage isolated to UIKit compatibility types, UIKit example components, or clearly named bridge/adaptor files that translate existing UIKit-backed providers into SwiftUI-native values.
- Prefer SwiftUI `Font`, `Color`, `View`, and environment-driven APIs for new package surfaces.

This file is both *how we work* (the conventions below) and *what we decided and why* (the **Decisions** section at the end). Read the decisions before changing public API or structure.

## Way of working

- **Theme is law.** Every Pinwheel surface resolves provider-backed tokens (`PinwheelTheme` / the `Config` providers), never Apple's system styles. Design API so the *wrong* (system-style) path is unrepresentable — that's why `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`.
- **One implementation per component.** A bridgeable component is a SwiftUI `Pin*` source plus a thin `UIKitPin*` shell that hosts it — never two parallel implementations. Theming/light-dark crosses the bridge for free because both sides read the same provider tokens.
- **Shared vocabularies are top-level types.** When two or more components reuse a concept, promote it to a top-level `public` type (`PinTextStyle`, `PinState`, `PinLabel.TextColor`) rather than nesting it under one component.
- **SwiftUI-native API.** Bare initializer + chained, themed modifiers (`PinLabel("x").font(.caption).color(.secondary)`, `PinButton("x") { }.style(.secondary).loading(flag)`). Mirror SwiftUI's own names where one exists (`systemImage:`, `.font(_:)`); `.font` is typography on any text component, `.style` is a button's visual variant. Raw escape hatches are explicit and named (`.color(.custom(...))`, `.style(.custom(text:background:))`). **Modifier naming:** chained modifiers on our *own* types are unprefixed; prefix with `pinwheel` *only* when extending a SwiftUI type to avoid collisions (`View.pinwheelTweaks { }`).
- **Verify visually, don't assume.** After a UI change, *look* before saying it's done:
  - Render the permanent `#Preview` in the catalog registry (`DemoPinwheelSections.swift`) — set `previewComponentID` and `RenderPreview` it (pass its current project-relative path; `XcodeGlob` finds it if it moved). No throwaway `#Preview` needed.
  - Or deep-link a booted sim: `simctl launch <bundle> -PinwheelPreview <id> [-PinwheelPreviewTweak <title>]`.
  - `Scripts/preview-all.sh` snapshots every component + tweak variant (light in `$OUT`, dark in `$OUT/dark`) for a full sweep.
  - When matching SwiftUI to UIKit, the UIKit example (or `main`) is the parity source of truth.
- **Build/verify via the Xcode MCP** — `BuildProject` after every change, `RenderPreview` to look, `RunSomeTests` for the regression tests (`tabIdentifier: "windowtab1"`). Setup + the session-restart gotcha live in the `xcode-mcp` skill; `xcodebuild`/`simctl` are the fallback.
- **Keep it green and current.** Builds stay warning-free. Update the **Decisions** section below as components change. Commit in small, focused units with clean, minimal messages; push when a logical unit is done.
- **Reference files by name + role, not full path.** Folders get reorganized and hard-coded paths rot; say "the catalog registry (`DemoPinwheelSections.swift`)" and grep/`XcodeGlob` for the current location. Top-level dirs that are part of the build contract (`Scripts/`, `DemoUITests`) are fine to name; the canonical folder map is in Decisions › Project layout.

## Testing

`DemoUITests` are **regression tests**, not a coverage goal. Add a UI test when a real bug/regression surfaces in an interactive path (e.g. a tap that stopped firing) — write the test that would have caught it. We do **not** aim for full UI coverage; don't add speculative UI tests for paths that haven't broken.

## Decisions

Durable design decisions and why they were made.

### Component surface (when a `Pin*` exists)

- Add a SwiftUI `Pin*` (with a thin `UIKitPin*` shell) **only when** SwiftUI lacks a first-class primitive, so styling would be hand-rolled anyway (`PinButton` — pill, variants, loading, symbol, haptics), **or** there's real imperative / UIKit-hosting value to bridge (`PinStateView` as a state machine a UIKit table can drive). If SwiftUI's primitive + `PinwheelTheme` already covers it and nothing needs to host it in UIKit, don't wrap it.
- **Exception — theme footguns get a wrapper anyway.** `Label → PinLabel` because raw `Text(...).font(.body)` silently resolves to Apple's system style (see Theme below). The test is "does the raw primitive bypass the theme?", not just "does a primitive exist?".
- **Switch → `Toggle`** (no standalone `PinSwitch`; the only switch lives inside the `UIKitPinTableView` family). **DNA (Font/Color/Spacing)** are *tokens*, never components, in either world.

### Bridging

- **One implementation per bridgeable component.** A `Pin*` SwiftUI source plus a thin `UIKitPin*` shell that hosts it (via `PinHostView`), never two parallel reimplementations. Theming, light/dark, and Dynamic Type cross the bridge for free because both worlds read the same `Config` providers.
- **Bridged: Button, StateView.** `UIKitPinButton` / `UIKitPinStateView` host the SwiftUI implementation. Trade-off: one `UIHostingController` per instance — acceptable for these leaf/overlay components; revisit for dense reused contexts (e.g. table cells).
- **State overlay centers via `centerY` in the shell**, not by filling. `PinHostView` sizes to intrinsic content, so a fill approach collapses to the top; centering lives in the shell, mirroring the old UIKit layout.
- **UIKit `view:` catalog items host at full bounds** via `PinwheelUIKitContainerViewController` (a `UIViewControllerRepresentable` handed the full proposed size), not a bare `UIViewRepresentable` (which sized to the fitting size and collapsed edge-pinned / table-backed examples to the top-left).
- **UIKit `Tweakable` options bridge into the playground.** A hosted `view:` item's UIKit `Tweak`s map to `PinwheelTweak`s (`TextTweak` → action, `BoolTweak` → toggle) and surface in the settings sheet.
- **A hosted UIKit `view:` is built once and reused.** `makeSwiftUIView` is called on every playground re-render; it must hand back the *same* `ViewType` instance each time. The bridged tweak closures capture that instance and the hosting controller displays it — a fresh instance per render makes the tweaks mutate an off-screen copy, so UIKit tweaks silently do nothing under nested presentation.

### Intentional UIKit surface (kept on purpose)

These stay UIKit because no SwiftUI primitive matches their ergonomics/perf:

- **`UIKitPinView` base** — `setup()` lifecycle, open subclassing.
- **`UIKitPinFullscreenView`** — a base class for keyboard-aware full-screen screens (forms/editors): bottom-anchored content rides above the keyboard, plus a synthesized `viewDidFirstAppear()` hook. Kept UIKit and has **no SwiftUI demo on purpose** — SwiftUI gives keyboard avoidance and `onAppear` for free, so there's nothing to build; a SwiftUI "FullscreenView" example would only imply a component that shouldn't exist.
- **`UIKitPinTableView` family** — cell recycling, dataSource/delegate contract, `UISwitch` items, A–Z section indexer; no `List` equivalent with comparable perf.

### Theme & shared vocabularies

- **Theme is law.** Every surface resolves provider-backed tokens (`PinwheelTheme` / `Config` providers), never Apple's system styles. API is designed so the wrong (system-style) path is unrepresentable.
- **Label → `PinLabel`** (themed `Text`) + an independent trivial `UIKitPinLabel`. Both are fed by the same provider tokens; neither hosts the other (a label needs no hosting bridge). `PinLabel` exists because raw `Text(...).font(.body)` resolves to *Apple's* system style — a silent footgun that regressed the demos. `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`, making the system-font path unrepresentable.
- **Shared vocabularies are top-level types**, so no component owns what another reuses: `PinTextStyle` (typography, used by `PinLabel` and `PinButton`), `PinState` (content state, promoted out of `PinStateView.State`, used by `PinStateView` and `PinList`), `PinLabel.TextColor` (color roles).
- **Color tokens have a SwiftUI-native shorthand.** A public `extension ShapeStyle where Self == Color` forwards the `PinwheelTheme.Colors` tokens, so any `ShapeStyle`/`Color` context takes a token the way it takes `.red` — `.background(.primaryBackground)`, `.foregroundStyle(.actionText)`. `PinwheelTheme.Colors` stays the canonical definition (the shorthand just forwards); prefer the leading-dot form at call sites. It can't reach `.listRowBackground(_:)` (parameter is a generic `View`, not a `ShapeStyle`), so those stay spelled out.
- **`PinList` is greenfield SwiftUI** (themed `List` + `PinState`, value-based rows) — the counterpart of `UIKitPinTableView`, *not* a replacement: the UIKit table stays for recycling. Non-loaded states reuse `PinStateView`.

### Project layout

- **Sources organized by domain, not access level.** `API/` (public surface), `DNA/` (tokens, both worlds, incl. SwiftUI `PinwheelTheme`), `Components/SwiftUI` + `Components/UIKit` (split by world; `TableView/` under UIKit), `Catalog/` (the one, pure-SwiftUI catalog + FAB + device/state), `Bridge/` (SwiftUI↔UIKit), `Extensions/`.
- **Demo mirrors the split** — `Demo/Examples/SwiftUI` + `Demo/Examples/UIKit`.
- **Both targets are file-system-synchronized groups**, so the folder layout *is* the project structure — moving/adding files needs no `project.pbxproj` edits. (The Demo app target's synced group excludes `Info.plist` so it isn't double-copied as a resource.)
- **Distribution nesting left as-is (deliberate):** the package lives in `Pinwheel/` (the Demo references it locally); a second root `Package.swift` re-exposes it for external `.package(url:)` consumers. Awkward (`Pinwheel/Sources/Pinwheel/`, two manifests) but changing it touches external import paths — not worth it now.

### Catalog, FAB & settings

- **One pure-SwiftUI catalog + one SwiftUI settings sheet.** The legacy UIKit-first catalog (`PinwheelTableViewController`, section/split VCs, the item-hosting `PinwheelViewController`/`PinwheelHostingViewController`, `TweakingOptionsTableViewController`, helpers) was removed — public-but-dead (instantiated nowhere; the Demo/README lead with the SwiftUI `PinwheelCatalog`, and `MIGRATION.md` exists to move off it). That removed the second (UIKit) settings sheet; `PinwheelItem.viewController` and the `makeViewController` path went with it. UIKit *components*, the bridges (`PinHostView`, `PinwheelUIKitCompatibility`), and the `PinwheelItem(view:)`/`(viewController:)` initializers that drop UIKit content *into* the SwiftUI catalog all stay.
- **Stable ids.** Persistence (selected section/item/device) keys off ids; prefer explicit ids over generated ones.
- **Registry doubles as the preview index.** `PinwheelPreview(id, sections:)` renders any catalog item in isolation; the Demo deep-links to one component via the `-PinwheelPreview <id>` launch arg.
- **One FAB, hosted in a pass-through overlay window.** The floating tweak/close controls are the single UIKit `CornerAnchoringView` (direct-manipulation drag + velocity throw + corner persistence), now used only by the SwiftUI catalog/preview, hosted in a `UIWindow` above the app (`PinwheelFloatingControlsHost`) so they float over sheet presentations and are never clipped to a `.medium`/`.large` detent; the window's `hitTest` surfaces only the FAB buttons, so content below stays interactive.
- **`PinwheelChrome` is the SwiftUI↔window seam** — an `@Observable` the catalog/preview owns and the window observes (tweaks, presented-state, settings visibility, selected device, close action). State lives here, not in playground `@State`, so the sheet, the playground resize, and the pill share one source of truth and survive re-renders.
- **Hosted items are built once** (`PinwheelHostedItem`) so playground re-renders (e.g. opening settings) don't recreate the hosted view or reset its emitted tweak preference.
- **Settings: tweaks and devices are separate screens.** A `NavigationStack` — an "Options" root (tweaks only) with a trailing device-icon button that pushes a "Device" list (oversized devices dimmed, the selected one checked).
- **The simulated device shows as a floating pill** (`PinwheelDevicePill`) — a top-anchored SwiftUI `.overlay` *on the playground itself* (not the FAB's overlay window), persisting after the settings sheet is dismissed. It's an indicator — only a reset `×` is interactive (returns to the real device). A simulated (smaller) device is letterboxed against `primaryText` (inverse-of-surface) so the frame is visible in light and dark. The pill rides the playground rather than the window so its shrink+fade is a plain SwiftUI `.transition` — hosting it in the window (`UIHostingController` + `.intrinsicContentSize`, top-pinned) collapsed its frame on the way out instead of scaling in place. Trade-off: behind the `.large` settings detent it's covered (fine — the device list shows the active checkmark); at `.medium` it still peeks above. The FAB still fades independently (the FAB hides while settings is open; the pill doesn't).
- **iPad device presets dropped** — the Device preset list was simplified.

### Open follow-ups

- **Bridged-component cost** — one `UIHostingController` per `UIKitPinButton`/`UIKitPinStateView`; revisit only if used in dense reused contexts (table cells). A watch-item, not actionable now.

(The "Recyclable" section was renamed from the misspelled "Reciclable"; its persisted id changed `reciclable` → `recyclable`, a one-time selection reset.)
