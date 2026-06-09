# Decisions

Durable design decisions for the SwiftUI-first Pinwheel and why they were made.
Working conventions and the build/verify loop live in `AGENTS.md`; testing policy
(regression-only XCUITests) is in `AGENTS.md` too.

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

## Follow-ups

- **Unify the settings sheet.** There are currently two: SwiftUI `PinwheelSettingsView`
  (SwiftUI catalog) and UIKit `TweakingOptionsTableViewController` (UIKit catalog /
  hosting VCs). Consolidating onto `PinwheelSettingsView` (hosted via
  `UIHostingController` for the UIKit path) would delete the UIKit one, but it means
  modifying the UIKit catalog VCs — deferred to avoid touching that path now.

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
  app via `PinwheelFloatingControls`). The window means the FAB floats over sheet
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
