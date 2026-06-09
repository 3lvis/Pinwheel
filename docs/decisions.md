# Decisions

Durable design decisions for the SwiftUI-first Pinwheel and why they were made.
Working conventions and the build/verify loop live in `AGENTS.md`; testing policy
(regression-only XCUITests) is in `AGENTS.md` too.

## Component surface (when a `Pin*` exists)

- Add a SwiftUI `Pin*` (with a thin `UIKitPin*` shell) **only when** SwiftUI lacks
  a first-class primitive, so styling would be hand-rolled anyway (`PinButton` —
  pill, variants, loading, symbol, haptics), **or** there's real imperative /
  UIKit-hosting value to bridge (`PinStateView` as a state machine a UIKit table
  can drive). If SwiftUI's primitive + `PinwheelTheme` already covers it and
  nothing needs to host it in UIKit, don't wrap it.
- **Exception — theme footguns get a wrapper anyway.** `Label → PinLabel` because
  raw `Text(...).font(.body)` silently resolves to Apple's system style (see Theme
  below). The test is "does the raw primitive bypass the theme?", not just "does a
  primitive exist?".
- **Switch → `Toggle`** (no standalone `PinSwitch`; the only switch lives inside
  the `UIKitPinTableView` family). **DNA (Font/Color/Spacing)** are *tokens*, never
  components, in either world.

## Bridging

- **One implementation per bridgeable component.** A `Pin*` SwiftUI source plus a
  thin `UIKitPin*` shell that hosts it (via `PinHostView`), never two parallel
  reimplementations. Theming, light/dark, and Dynamic Type cross the bridge for
  free because both worlds read the same `Config` providers.
- **Bridged: Button, StateView.** `UIKitPinButton` / `UIKitPinStateView` host the
  SwiftUI implementation. Trade-off: one `UIHostingController` per instance —
  acceptable for these leaf/overlay components; revisit for dense reused contexts
  (e.g. table cells).
- **State overlay centers via `centerY` in the shell**, not by filling.
  `PinHostView` sizes to intrinsic content, so a fill approach collapses to the
  top; centering lives in the shell, mirroring the old UIKit layout.
- **UIKit `view:` catalog items host at full bounds** via
  `PinwheelUIKitContainerViewController` (a `UIViewControllerRepresentable` handed
  the full proposed size), not a bare `UIViewRepresentable` (which sized to the
  fitting size and collapsed edge-pinned / table-backed examples to the top-left).
- **UIKit `Tweakable` options bridge into the playground.** A hosted `view:` item's
  UIKit `Tweak`s map to `PinwheelTweak`s (`TextTweak` → action, `BoolTweak` →
  toggle) and surface in the settings sheet.
- **A hosted UIKit `view:` is built once and reused.** `makeSwiftUIView` is called
  on every playground re-render; it must hand back the *same* `ViewType` instance
  each time. The bridged tweak closures capture that instance and the hosting
  controller displays it — a fresh instance per render makes the tweaks mutate an
  off-screen copy, so UIKit tweaks silently do nothing under nested presentation.

## Intentional UIKit surface (kept on purpose)

These stay UIKit because no SwiftUI primitive matches their ergonomics/perf:

- **`UIKitPinView` base** — `setup()` lifecycle, open subclassing.
- **`UIKitPinFullscreenView`** — a base class for keyboard-aware full-screen
  screens (forms/editors): bottom-anchored content rides above the keyboard, plus
  a synthesized `viewDidFirstAppear()` hook. Kept UIKit and has **no SwiftUI demo
  on purpose** — SwiftUI gives keyboard avoidance and `onAppear` for free, so
  there's nothing to build; a SwiftUI "FullscreenView" example would only imply a
  component that shouldn't exist.
- **`UIKitPinTableView` family** — cell recycling, dataSource/delegate contract,
  `UISwitch` items, A–Z section indexer; no `List` equivalent with comparable perf.

## Theme & shared vocabularies

- **Theme is law.** Every surface resolves provider-backed tokens
  (`PinwheelTheme` / `Config` providers), never Apple's system styles. API is
  designed so the wrong (system-style) path is unrepresentable.
- **Label → `PinLabel`** (themed `Text`) + an independent trivial `UIKitPinLabel`.
  Both are fed by the same provider tokens; neither hosts the other (a label needs
  no hosting bridge). `PinLabel` exists because raw `Text(...).font(.body)`
  resolves to *Apple's* system style — a silent footgun that regressed the demos.
  `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`, making the
  system-font path unrepresentable. (Supersedes the earlier "no `PinLabel`,
  use `Text` directly" decision.)
- **Shared vocabularies are top-level types**, so no component owns what another
  reuses: `PinTextStyle` (typography, used by `PinLabel` and `PinButton`),
  `PinState` (content state, promoted out of `PinStateView.State`, used by
  `PinStateView` and `PinList`), `PinLabel.TextColor` (color roles).
- **`PinList` is greenfield SwiftUI** (themed `List` + `PinState`, value-based
  rows) — the counterpart of `UIKitPinTableView`, *not* a replacement: the UIKit
  table stays for recycling. Non-loaded states reuse `PinStateView`.

## Project layout

- **Sources organized by domain, not access level.** `API/` (public surface),
  `DNA/` (tokens, both worlds, incl. SwiftUI `PinwheelTheme`), `Components/SwiftUI`
  + `Components/UIKit` (split by world; `TableView/` under UIKit), `Catalog/` (the
  one, pure-SwiftUI catalog + FAB + device/state), `Bridge/` (SwiftUI↔UIKit),
  `Extensions/`.
- **Demo mirrors the split** — `Demo/Examples/SwiftUI` + `Demo/Examples/UIKit`.
- **Both targets are file-system-synchronized groups**, so the folder layout *is*
  the project structure — moving/adding files needs no `project.pbxproj` edits.
  (The Demo app target's synced group excludes `Info.plist` so it isn't double-
  copied as a resource.)
- **Distribution nesting left as-is (deliberate):** the package lives in `Pinwheel/`
  (the Demo references it locally); a second root `Package.swift` re-exposes it for
  external `.package(url:)` consumers. Awkward (`Pinwheel/Sources/Pinwheel/`, two
  manifests) but changing it touches external import paths — not worth it now.

## Catalog & settings are pure SwiftUI

- **One catalog, one settings sheet — both SwiftUI.** The legacy UIKit-first catalog
  (`PinwheelTableViewController` + section/split VCs + the item-hosting
  `PinwheelViewController`/`PinwheelHostingViewController` + `TweakingOptionsTableViewController`
  + helpers) was removed: it was public-but-dead (instantiated nowhere; the Demo and
  README lead with the SwiftUI `PinwheelCatalog`, and `MIGRATION.md` exists to move
  off it). That deleted the second (UIKit) settings sheet as a side effect, leaving
  only SwiftUI `PinwheelSettingsView`. `PinwheelItem.viewController` and the
  `makeViewController` path went with it.
- **UIKit compatibility is unchanged** — the UIKit *component* surface
  (`UIKitPinView`/`Button`/`StateView`/`Label`/`FullscreenView`, the
  `UIKitPinTableView` family), the bridges (`PinHostView`,
  `PinwheelUIKitCompatibility`), and the `PinwheelItem(view:)`/`(viewController:)`
  initializers that drop UIKit content *into* the SwiftUI catalog all stay. You just
  can't build the catalog *host* in UIKit anymore (nothing did).

## Open follow-ups

Audited TODOs (nothing else is pending):

1. **Bridged-component cost** — one `UIHostingController` per `UIKitPinButton`/
   `UIKitPinStateView`; revisit only if used in dense reused contexts (table cells).
   A watch-item, not actionable now.

(The "Recyclable" section was renamed from the misspelled "Reciclable"; its
persisted id changed `reciclable` → `recyclable`, a one-time selection reset.)

## Catalog

- **Stable ids.** Persistence (selected section/item/device) keys off ids; prefer
  explicit ids over generated ones.
- **iPad device presets dropped** — the Device preset list was simplified.
- **Registry doubles as the preview index.** `PinwheelPreview(id, sections:)`
  renders any catalog item in isolation; the Demo deep-links to one component via
  the `-PinwheelPreview <id>` launch arg.
- **One FAB, hosted in a pass-through overlay window.** The floating tweak/close
  controls are the single UIKit `CornerAnchoringView` (direct-manipulation drag +
  velocity throw + corner persistence) — used by both the UIKit catalog (embedded
  in its VCs) and the SwiftUI catalog/preview (hosted in a `UIWindow` above the
  app via `PinwheelFloatingControlsHost`). The window means the FAB floats over sheet
  presentations and is never clipped to a `.medium`/`.large` detent; its
  `hitTest` returns only the FAB buttons so the content below stays interactive.
  The deleted SwiftUI `PinwheelFloatingControls`/`PinwheelFloatingButton` were a
  second, hand-rolled FAB with worse ergonomics.
- **`PinwheelChrome` is the SwiftUI↔window seam.** An `@Observable` the catalog/
  preview owns and the window observes: tweaks (held here, not in playground
  `@State`, so they survive re-renders), presented-state, settings visibility,
  and the close action. The FAB hides while the settings sheet is open
  (`isPresentingItem && !showsSettings`) so settings can't be opened over itself.
- **Hosted items are built once** (`PinwheelHostedItem`) so playground re-renders
  (e.g. opening settings) don't recreate the hosted view or reset its emitted
  tweak preference.
