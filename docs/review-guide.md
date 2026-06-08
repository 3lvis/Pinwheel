# Review Guide — `swiftui` branch

This branch turns Pinwheel into a **SwiftUI-first** package while keeping UIKit compatibility. It's a large, cohesive change (≈59 files vs `main`); this guide is the suggested order to review it, the decisions worth scrutinizing, and how to verify each piece. Check boxes as you go.

> Scope: everything in `git diff main..swiftui`. The most recent work (the SwiftUI→UIKit bridge, single-component preview, and StateView collapse) is the freshest and has the only open questions — start there if time is short.

## TL;DR of what changed

- **SwiftUI-first API**: `PinwheelCatalog` / `PinwheelSection` / `PinwheelItem` now lead with SwiftUI `@ViewBuilder` content; UIKit views/controllers are still first-class via dedicated initializers.
- **One implementation per bridgeable component**: `PinButton` and `PinStateView` are the single SwiftUI source of truth; `UIKitPin*` are thin hosts over them, not parallel reimplementations.
- **SwiftUI→UIKit bridge**: `PinHostView` drops a `Pin*` component into a UIKit hierarchy as a self-sizing view.
- **Registry-driven preview**: `PinwheelPreview` renders any catalog item by id in isolation; the Demo can deep-link straight to one component.
- **Intentional UIKit surface**: `UIKitPinView`, `UIKitPinFullscreenView`, the `UIKitPinTableView` family, and `UIKitPinLabel` stay UIKit on purpose, now each documented as such.

## Suggested reading order

### 1. Public API shape — start here
- [ ] `Pinwheel/Sources/Pinwheel/Public/Pinwheel.swift` — `PinwheelSection`, `PinwheelItem` (all initializers: SwiftUI `@ViewBuilder`, `UIView.Type`, `UIViewController` factory), fluent modifiers (`pinwheelPresentation`, `pinwheelSafeArea`, …), `PinwheelCatalog`. **The core contract.** Confirm the initializer overloads are unambiguous and the id-generation fallback reads sensibly.
- [ ] `Public/PinwheelTheme.swift` — SwiftUI `Font`/`Color` surface backed by the existing `Config` providers.
- [ ] `Public/PinwheelTweak.swift` + `pinwheelTweaks` — the preference-key-driven tweak system.

### 2. The bridge + preview plumbing (freshest)
- [ ] `Public/PinwheelHostView.swift` — `PinHostView<Content>`: owns a `UIHostingController`, publishes intrinsic content size, and **re-parents the hosting controller to the nearest view controller in `didMoveToWindow()`**. Scrutinize the lifecycle (add/remove child VC) — this is the subtlest code in the branch.
- [ ] `Extensions/UIViewExtensions.swift` — `parentViewController` responder-chain walk used above.
- [ ] `Public/PinwheelPreview.swift` — `PinwheelPreview(id, sections:)` resolves a catalog id to the same isolated render the catalog uses; `requestedID` reads the launch arg / env var for deep-linking. Check the id-resolution (bare vs `sectionID/itemID`) and the not-found fallback.

### 3. Components — one impl + thin shell
- [ ] `Components/PinButton.swift` — SwiftUI source of truth (styles, loading, symbol, haptics).
- [ ] `Components/UIKitPinButton.swift` — thin `UIControl` shell over `PinButton` (target-action, `title`/`isEnabled`/`isLoading`).
- [ ] `Components/PinStateView.swift` — SwiftUI state view; `.loaded` renders clear (overlay-friendly), `.failed` uses `PinButton`.
- [ ] `Components/UIKitPinStateView.swift` — thin shell; **kept `UIKitPinStateViewState` + delegate identical** so `UIKitPinTableView`'s overlay needed no edits. Note the `centerY` layout and the `alpha` (loaded → hidden) contract.

### 4. Catalog / playground internals
- [ ] `Public/PinwheelCatalogView.swift`, `Public/PinwheelPlayground.swift`, `Public/PinwheelHostingViewController.swift` — navigation, presentation (sheet/fullscreen detents), device frame + size-class injection, floating tweak/close controls, state restoration by id.
- [ ] `Core/Tweakable/Device.swift` — device presets were simplified (iPad presets dropped). Confirm that's intended.

### 5. Intentional UIKit surface (kept on purpose)
- [ ] `Components/View/UIKitPinView.swift`, `Components/View/UIKitPinFullscreenView.swift`, `Reciclable/TableView/UIKitPinTableView.swift`, `Components/Label/UIKitPinLabel.swift` — each now opens with an "Intentional UIKit surface" doc-comment explaining why it doesn't bridge. Verify the rationale holds.

### 6. Demo + docs
- [ ] `Demo/AppDelegate.swift`, `Demo/SwiftUIExamples/DemoPinwheelSections.swift`, `Demo/SwiftUIExamples/ComponentSwiftUIExamples.swift`, and the `Demo/Pins/.../UIKitPin*Example.swift` files — naming convention (SwiftUI `Pin*Example`, UIKit `UIKitPin*Example`).
- [ ] `README.md`, `MIGRATION.md`, `docs/swiftui-uikit-bridge.md` — the bridge plan doc records the phase-by-phase rationale.

## Decisions worth a second look

1. **Thin shell, not reimplementation.** `UIKitPinButton`/`UIKitPinStateView` host the SwiftUI component rather than duplicating it. Trade-off: a `UIHostingController` per instance. Acceptable for these leaf/overlay components; revisit if used in dense reused contexts (e.g. table cells).
2. **State overlay centers via `centerY` in the shell**, not by filling. `PinHostView`'s intrinsic-content-size sizing makes a fill approach collapse to the top, so centering lives in the shell (mirrors the old `subtitleLabel.centerYAnchor` layout). Correct in a real full-bounds container.
3. **Keep `UIKitPinLabel`, no SwiftUI `PinLabel`.** Hosting a label costs more than the bridge is worth; SwiftUI code uses `Text` + `PinwheelTheme` directly.
4. **Stable ids.** Persistence (selected section/item/device) keys off ids — encourages explicit ids over generated ones.

## How to verify

```sh
# Build (Demo target embeds the package)
xcodebuild -scheme Demo -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Deep-link straight to a component (bundle id: com.nordser.pinwheel)
xcrun simctl launch <booted-device> com.nordser.pinwheel -PinwheelPreview button
xcrun simctl launch <booted-device> com.nordser.pinwheel -PinwheelPreview uikit-button
xcrun simctl launch <booted-device> com.nordser.pinwheel -PinwheelPreview state-view
```

Verified this session: `button` (SwiftUI), `uikit-button` (bridge), `state-view` / `uikit-state-view`, and the unknown-id index render correctly; the SwiftUI `PinStateView` centers; the package + Demo build clean.

## Open follow-ups (not blocking)

- **UIKit-component previews render top-anchored in the playground.** `PinwheelUIKitView` (the `UIViewRepresentable`) doesn't propagate full height, so a hosted UIKit example collapses to content height. Pre-existing (old StateView looked identical); the component centers correctly in the pure-SwiftUI path and in real full-bounds UIKit hierarchies. A `sizeThatFits` fill attempt had no observable effect and was reverted — it needs a deeper look at how the playground frames representable-hosted UIKit views, not a one-line fix.
- **Greenfield SwiftUI `PinList`** — explicitly deferred; would *not* replace `UIKitPinTableView`.

## Risk checklist

- [ ] `PinHostView` child-VC re-parenting handles being added/removed from windows repeatedly without detached-controller warnings.
- [ ] No `import UIKit` leaked into SwiftUI-first views/examples/call sites (per `CLAUDE.md`).
- [ ] Swift 6.3 / `MainActor` default isolation: no concurrency warnings introduced.
- [ ] Theming (`Config` providers), light/dark, and Dynamic Type still resolve across the SwiftUI↔UIKit boundary.
- [ ] Dropped iPad device presets don't break any existing demo expectations.
