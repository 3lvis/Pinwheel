# TODO — One component implementation, usable from UIKit

## Context

Pinwheel is SwiftUI-first with UIKit compatibility. A prior pass created **two parallel implementations** of each component — SwiftUI `Pin*` and a full UIKit reimplementation `UIKitPin*`. That was not the intent.

**Intended outcome:** one implementation per component (the SwiftUI `Pin*`), **usable from a UIKit/hybrid app** with the same theming and usage ergonomics the old `main` API had. Keep a UIKit type **only** where the SwiftUI component can't be bridged with comparable ergonomics/perf — and when kept, make it a **thin host over the SwiftUI implementation**, not a parallel reimplementation. The UIKit story exists to show: "Pinwheel is SwiftUI-first, yet drops into a mixed SwiftUI/UIKit app with first-class components and theming."

**What makes this tractable:**
- Theming is already single-source: `Config.colorProvider`/`fontProvider` → `UIColor`/`UIFont` extensions → `PinwheelTheme`. One provider drives both worlds; light/dark resolves across a hosting boundary for free.
- The only missing seam is **SwiftUI→UIKit** (drop a `Pin*` view into a UIKit hierarchy). `PinwheelUIKitView` only does the reverse; `PinwheelHostingViewController` is a full-screen catalog host.

## Overall success criteria

- [x] A UIKit consumer can place a SwiftUI `Pin*` component into a `UIStackView`/Auto Layout hierarchy as a self-sizing view, with no SwiftUI knowledge required at the call site.
- [x] Theming (`Config` providers), light/dark, and Dynamic Type all work through the bridge with zero extra wiring.
- [x] For bridgeable components (Button, StateView): exactly **one** implementation (SwiftUI), plus a thin `UIKitPin*` shell; the old full UIKit reimplementation is deleted.
- [x] For non-bridgeable components (FullscreenView, `View` base, TableView family): kept as UIKit, explicitly documented as the intentional UIKit surface.
- [x] Package + Demo build clean (`mcp__xcode__BuildProject`); the UIKit Button demo renders pixel-identical to before.

## Architecture decisions

| Component | Decision | Why |
|---|---|---|
| **Button** | SwiftUI `PinButton` (exists) + thin `UIKitPinButton` shell over `PinHostView`; delete old reimpl | Declarative leaf; already ported |
| **StateView** | SwiftUI `PinStateView` + thin shell; delete reimpl | Pure state-driven content |
| **Label** | Keep trivial `UIKitPinLabel` (`UILabel` subclass); optional SwiftUI `PinLabel` | Bridge overhead not worth it |
| **FullscreenView / `View` base** | Keep UIKit, unchanged | Keyboard avoidance, lifecycle hooks, open subclassing — inherently UIKit |
| **TableView family** | Keep UIKit, unchanged | Cell recycling, dataSource/delegate contract, `UISwitch` items, A–Z section indexer (`Core/Indexer.swift`) — no `List` equivalent |

---

## Phase 1 — Bridge foundation ✅ DONE

- [x] Add `PinHostView<Content: SwiftUI.View>: UIView` → new `Pinwheel/Sources/Pinwheel/Public/PinwheelHostView.swift`. Owns a `UIHostingController(rootView:)`, `sizingOptions = .intrinsicContentSize`, pins hosting view to all 4 edges (no safe-area inset), `var rootView` for re-render, re-parents hosting controller to nearest VC in `didMoveToWindow()`.
- [x] Add `parentViewController` responder-chain helper → `Extensions/UIViewExtensions.swift`.

**Success:** `PinHostView { PinButton("Hi"){} }` self-sizes in a vertical `UIStackView` (`.center`), propagates light/dark + Dynamic Type, no detached-controller bugs. Builds via MCP.

## Phase 2 — Button (proof of concept) ✅ DONE

- [x] Add haptics to `PinButton` via `.sensoryFeedback` (parity with old press feedback) → `Components/PinButton.swift`.
- [x] Replace full reimpl in `Components/UIKitPinButton.swift` with a thin shell: `UIView` owning `PinHostView<PinButton>`; imperative `title`/`isEnabled`/`isLoading`/`onTap` (`didSet` re-render via small state object); `showActivityIndicator(_:)` shim (→ `isLoading`).
- [x] Port `Demo/Pins/Components/UIKitPinButtonExample.swift` to the shell (should compile ~unchanged) — conformance test.
- [x] Delete the old reimplementation once parity confirmed.

**Success:** UIKit Button demo renders identical to before; enabled/loading toggle through the shell; one `PinButton` implementation only. Verify via `RenderPreview` + the demo screen.

## Phase 3 — StateView ✅ DONE

- [x] Build SwiftUI `PinStateView` from the `loading/loaded/empty/failed` enum → new `Components/PinStateView.swift`. `.loaded` renders nothing (clear), so it works as an overlay; `.failed` uses a `PinButton` for the action.
- [x] Replace `UIKitPinStateView` with a thin shell: `UIView` hosting `PinHostView<PinStateView>`, preserving `state` / `delegate` (back-compat) and adding `onAction`. Old reimpl deleted.
- [x] Internal users repointed for free: keeping `UIKitPinStateViewState` + `UIKitPinStateViewDelegate` identical means `UIKitPinTableView`'s overlay needed no changes. SwiftUI demo (`PinStateViewExample`) now drives the real `PinStateView`.

**Success:** ✅ both SwiftUI and UIKit demos drive the same `PinStateView`; states switch correctly; builds clean. Verified via deep-link previews (`state-view`, `uikit-state-view`).

**Note — shell centers via `centerY`:** `PinStateView` hugs its content; the shell centers it with a `centerYAnchor` constraint, mirroring the old UIKit layout. This needs a full-bounds host — see the VC-container fix below.

## Post-phase fixes

These landed after Phases 1–5 while exercising the catalog/preview:

- [x] **UIKit catalog items now host at full bounds.** `view:` items were embedded via `PinwheelUIKitView` (a bare `UIViewRepresentable`), which sized the hosted view to its *fitting* size — so edge-pinned examples (DNA Spacing) collapsed top-left, `UITableView`-backed examples (Color, TableView) rendered blank, and the StateView overlay couldn't center. Fix: host each `view:` item in `PinwheelUIKitContainerViewController` (pins the view to fill) wrapped in `PinwheelUIKitViewController`; a `UIViewControllerRepresentable` is handed the full proposed size. This fixed Spacing, the blank tables, the StateView centering, **and** the StateView Retry button (the inner `PinHostView` `UIHostingController` now has a real VC ancestor to parent to, so SwiftUI button taps fire). Verified by deep-link + an automated tap.
- [x] **UIKit `Tweakable` options bridged into the SwiftUI playground.** A hosted `view:` item that conforms to `Tweakable` maps its UIKit `Tweak`s (`TextTweak` → action, `BoolTweak` → toggle) to `PinwheelTweak`s and publishes them via `pinwheelTweaks`, so its options appear in the playground settings sheet (previously absent for UIKit examples). See `PinwheelUIKitCompatibility.swift`.
- [x] **iOS 17 deprecations + Sendable warnings cleared** (trait overrides, `onChange`, `UITraitCollection(traitsFrom:)`, tweak toggle binding). Build is warning-free.

## Phase 4 — Label decision ✅ DONE

- [x] **Decision: keep `UIKitPinLabel` as-is; no SwiftUI `PinLabel`.** A label routed through a hosting controller costs more than the bridge is worth. SwiftUI-first code uses `Text` with `PinwheelTheme.Typography`/`Colors` directly (see `PinLabelExample`). Recorded as a doc-comment on `UIKitPinLabel`.

## Phase 5 — Document the intentional UIKit surface ✅ DONE

- [x] `UIKitPinFullscreenView`, the `UIKitPinView` base, and the `UIKitPinTableView` family left as-is.
- [x] Doc-comment convention applied: each genuinely-UIKit type now opens with an "Intentional UIKit surface" note explaining why it can't bridge with comparable ergonomics/perf (keyboard avoidance + lifecycle for FullscreenView; `setup()` lifecycle + open subclassing for the base View; cell recycling / dataSource-delegate / `UISwitch` / A–Z indexer for TableView; hosting-overhead for Label). The thin-host shells (`UIKitPinButton`, `UIKitPinStateView`) already document themselves as hosts over the SwiftUI source.
- [ ] (Later / optional) a greenfield SwiftUI `PinList` — explicitly NOT a replacement for `UIKitPinTableView`.

---

## Verification (per step)

- Fast compile: `mcp__xcode__BuildProject` (windowtab1).
- Visual: `mcp__xcode__RenderPreview` on a temporary `#Preview` (remove after).
- Full app launch only when genuinely needed: `simctl launch` the MCP-built app (not slow osascript).
- Button POC gate: compare the UIKit demo pill to the current build; confirm self-sizing in the stack view, enabled/loading toggles, light/dark.

## Backlog

- [x] **Built-in preview/iteration plumbing — make agent iteration on components blazing fast.** ✅ DONE. The `PinwheelSection`/`PinwheelItem` registry is now the preview index; `PinwheelPreview` resolves an id to the same isolated render the catalog uses.
  - `PinwheelPreview(_ id:sections:)` (`Public/PinwheelPreview.swift`) — renders one component by id in isolation. `id` is bare (`"button"`) or qualified (`"sectionID/itemID"`); an unknown id renders the full id index.
  - **Deep-link, no temp files:** `DemoApp` branches on `PinwheelPreview.requestedID` (reads `-PinwheelPreview <id>` launch arg / `PINWHEEL_PREVIEW` env). One call renders any component, including UIKit ones and sheet/fullscreen presentations:
    `xcrun simctl launch <booted> com.nordser.pinwheel -PinwheelPreview button` → screenshot.
  - **RenderPreview fast path:** one permanent `#Preview` lives at the bottom of `DemoPinwheelSections.swift`; edit the `previewComponentID` constant (one token) to point it at any component — no throwaway `#Preview` files.

- [x] **XCUITest coverage for interactive playground paths.** ✅ STARTED. The `DemoUITests` target drives the deep-link launch arg, so each test is a one-line jump to a single component, then taps real UI:
  ```swift
  app.launchArguments = ["-PinwheelPreview", "uikit-state-view"]
  app.launch()
  app.buttons["pinwheel.settings"].tap()   // wrench (a11y id)
  app.buttons["Failed"].tap()              // bridged tweak
  XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: 10))
  app.buttons["Retry"].tap()               // failed-state action fires
  XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 10))
  ```
  - `DemoUITests/StateViewUITests.swift` covers the SwiftUI `PinStateView` and the UIKit shell: default render, the `Tweakable`→SwiftUI tweak bridge, and the failed-state Retry action (all green via `xcodebuild test -scheme Demo`).
  - Testability hooks added: `pinwheel.settings` / `pinwheel.close` accessibility ids on the playground floating controls; the UIKit StateView demo's Retry now switches to `.loading` (observable, matching the SwiftUI demo).
  - Follow-up: extend to Button (enabled/loading) and the TableView family.

## Critical files

- `Pinwheel/Sources/Pinwheel/Public/PinwheelPreview.swift` — **new** preview/deep-link entry point (id → isolated render)
- `Pinwheel/Sources/Pinwheel/Public/PinwheelHostView.swift` — **new** SwiftUI→UIKit bridge (host a `Pin*` view in UIKit)
- `Pinwheel/Sources/Pinwheel/Public/PinwheelUIKitCompatibility.swift` — `PinwheelUIKitView`/`PinwheelUIKitViewController`, the full-bounds `PinwheelUIKitContainerViewController`, and the `Tweak` → `PinwheelTweak` bridge
- `Pinwheel/Sources/Pinwheel/Extensions/UIViewExtensions.swift` — `parentViewController`; `applyDeviceTraitOverrides`
- `Pinwheel/Sources/Pinwheel/Components/PinButton.swift` — SwiftUI source of truth (+ haptics)
- `Pinwheel/Sources/Pinwheel/Components/UIKitPinButton.swift` — thin shell (replaces reimpl)
- `Pinwheel/Sources/Pinwheel/Components/UIKitPinStateView.swift` + new `PinStateView.swift`
- `Demo/Pins/Components/UIKitPinButtonExample.swift` — conformance test
