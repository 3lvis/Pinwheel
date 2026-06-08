# TODO — One component implementation, usable from UIKit

## Context

Pinwheel is SwiftUI-first with UIKit compatibility. A prior pass created **two parallel implementations** of each component — SwiftUI `Pin*` and a full UIKit reimplementation `UIKitPin*`. That was not the intent.

**Intended outcome:** one implementation per component (the SwiftUI `Pin*`), **usable from a UIKit/hybrid app** with the same theming and usage ergonomics the old `main` API had. Keep a UIKit type **only** where the SwiftUI component can't be bridged with comparable ergonomics/perf — and when kept, make it a **thin host over the SwiftUI implementation**, not a parallel reimplementation. The UIKit story exists to show: "Pinwheel is SwiftUI-first, yet drops into a mixed SwiftUI/UIKit app with first-class components and theming."

**What makes this tractable:**
- Theming is already single-source: `Config.colorProvider`/`fontProvider` → `UIColor`/`UIFont` extensions → `PinwheelTheme`. One provider drives both worlds; light/dark resolves across a hosting boundary for free.
- The only missing seam is **SwiftUI→UIKit** (drop a `Pin*` view into a UIKit hierarchy). `PinwheelUIKitView` only does the reverse; `PinwheelHostingViewController` is a full-screen catalog host.

## Overall success criteria

- [ ] A UIKit consumer can place a SwiftUI `Pin*` component into a `UIStackView`/Auto Layout hierarchy as a self-sizing view, with no SwiftUI knowledge required at the call site.
- [ ] Theming (`Config` providers), light/dark, and Dynamic Type all work through the bridge with zero extra wiring.
- [ ] For bridgeable components (Button, StateView): exactly **one** implementation (SwiftUI), plus a thin `UIKitPin*` shell; the old full UIKit reimplementation is deleted.
- [ ] For non-bridgeable components (FullscreenView, `View` base, TableView family): kept as UIKit, explicitly documented as the intentional UIKit surface.
- [ ] Package + Demo build clean (`mcp__xcode__BuildProject`); the UIKit Button demo renders pixel-identical to before.

## Architecture decisions

| Component | Decision | Why |
|---|---|---|
| **Button** | SwiftUI `PinButton` (exists) + thin `UIKitPinButton` shell over `PinHostView`; delete old reimpl | Declarative leaf; already ported |
| **StateView** | SwiftUI `PinStateView` + thin shell; delete reimpl | Pure state-driven content |
| **Label** | Keep trivial `UIKitPinLabel` (`UILabel` subclass); optional SwiftUI `PinLabel` | Bridge overhead not worth it |
| **FullscreenView / `View` base** | Keep UIKit, unchanged | Keyboard avoidance, lifecycle hooks, open subclassing — inherently UIKit |
| **TableView family** | Keep UIKit, unchanged | Cell recycling, dataSource/delegate contract, `UISwitch` items, A–Z section indexer (`Core/Indexer.swift`) — no `List` equivalent |

---

## Phase 1 — Bridge foundation

- [ ] Add `PinHostView<Content: SwiftUI.View>: UIView` → new `Pinwheel/Sources/Pinwheel/Public/PinwheelHostView.swift`. Owns a `UIHostingController(rootView:)`, `sizingOptions = .intrinsicContentSize`, pins hosting view to all 4 edges (no safe-area inset), `var rootView` for re-render, re-parents hosting controller to nearest VC in `didMoveToWindow()`.
- [ ] Add `parentViewController` responder-chain helper → `Extensions/UIViewExtensions.swift`.

**Success:** `PinHostView { PinButton("Hi"){} }` self-sizes in a vertical `UIStackView` (`.center`), propagates light/dark + Dynamic Type, no detached-controller bugs. Builds via MCP.

## Phase 2 — Button (proof of concept)

- [ ] Add haptics to `PinButton` via `.sensoryFeedback` (parity with old press feedback) → `Components/PinButton.swift`.
- [ ] Replace full reimpl in `Components/UIKitPinButton.swift` with a thin shell: `UIView` owning `PinHostView<PinButton>`; imperative `title`/`isEnabled`/`isLoading`/`onTap` (`didSet` re-render via small state object); `showActivityIndicator(_:)` shim (→ `isLoading`).
- [ ] Port `Demo/Pins/Components/UIKitPinButtonExample.swift` to the shell (should compile ~unchanged) — conformance test.
- [ ] Delete the old reimplementation once parity confirmed.

**Success:** UIKit Button demo renders identical to before; enabled/loading toggle through the shell; one `PinButton` implementation only. Verify via `RenderPreview` + the demo screen.

## Phase 3 — StateView

- [ ] Build SwiftUI `PinStateView` from the `loading/loaded/empty/failed` enum → new `Components/PinStateView.swift`.
- [ ] Add thin `UIKitPinStateView` shell (`var state`, `onAction`); delete reimpl.
- [ ] Repoint internal users (incl. `UIKitPinTableView`'s state overlay) to the shell/SwiftUI impl.

**Success:** both SwiftUI and UIKit demos drive the same `PinStateView`; states switch correctly; builds.

## Phase 4 — Label decision

- [ ] Decide: keep `UIKitPinLabel` as-is, and/or add a SwiftUI `PinLabel`. (Low priority.)

## Phase 5 — Document the intentional UIKit surface

- [ ] Leave `UIKitPinFullscreenView`, `UIKitPinView` base, and the `UIKitPinTableView` family as-is.
- [ ] Add a doc-comment convention clarifying `UIKitPin*` now means either "thin host over SwiftUI" (Button, StateView) or "genuinely UIKit" (FullscreenView, TableView).
- [ ] (Later / optional) a greenfield SwiftUI `PinList` — explicitly NOT a replacement for `UIKitPinTableView`.

---

## Verification (per step)

- Fast compile: `mcp__xcode__BuildProject` (windowtab1).
- Visual: `mcp__xcode__RenderPreview` on a temporary `#Preview` (remove after).
- Full app launch only when genuinely needed: `simctl launch` the MCP-built app (not slow osascript).
- Button POC gate: compare the UIKit demo pill to the current build; confirm self-sizing in the stack view, enabled/loading toggles, light/dark.

## Backlog

- [ ] **Built-in preview/iteration plumbing — make agent iteration on components blazing fast.** Today, visually checking a component means hand-writing a throwaway `#Preview` (or launching the whole app), which is slow and repetitive. Pinwheel should ship the plumbing to render *any* component in isolation with zero scaffolding — e.g. a `PinwheelPreview(componentID)` / catalog-driven snapshot entry point, and/or a way to deep-link the Demo app straight to a component (id) so an agent can `simctl launch` + screenshot a single component instantly. Goal: render-any-component-in-one-call, no temp `#Preview` files. (The catalog already enumerates every component via `PinwheelSection`/`PinwheelItem` — reuse that registry as the preview index.)

## Critical files

- `Pinwheel/Sources/Pinwheel/Public/PinwheelHostView.swift` — **new** bridge
- `Pinwheel/Sources/Pinwheel/Extensions/UIViewExtensions.swift` — `parentViewController`
- `Pinwheel/Sources/Pinwheel/Components/PinButton.swift` — SwiftUI source of truth (+ haptics)
- `Pinwheel/Sources/Pinwheel/Components/UIKitPinButton.swift` — thin shell (replaces reimpl)
- `Pinwheel/Sources/Pinwheel/Components/UIKitPinStateView.swift` + new `PinStateView.swift`
- `Demo/Pins/Components/UIKitPinButtonExample.swift` — conformance test
