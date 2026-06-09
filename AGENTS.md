# Agent Guidelines

- Treat Pinwheel as a SwiftUI-first package with UIKit compatibility.
- Do not add `import UIKit` to SwiftUI-first views, SwiftUI examples, or SwiftUI API call sites.
- Keep UIKit usage isolated to UIKit compatibility types, UIKit example components, or clearly named bridge/adaptor files that translate existing UIKit-backed providers into SwiftUI-native values.
- Prefer SwiftUI `Font`, `Color`, `View`, and environment-driven APIs for new package surfaces.

## When to add a SwiftUI `Pin*` component

Add a SwiftUI `Pin*` component (with its thin `UIKitPin*` shell) only when **either**:
1. SwiftUI lacks a first-class primitive for it, so styling would be hand-rolled anyway (e.g. `PinButton` — the pill, style variants, loading, symbol, haptics need a custom `ButtonStyle`), **or**
2. there's real imperative / UIKit-hosting value worth bridging (e.g. `PinStateView` as a state machine a UIKit table can drive).

If SwiftUI's native primitive plus `PinwheelTheme` already covers it and nothing needs to host it in UIKit, **do not wrap it** — unless using the raw primitive silently bypasses the theme (see Label):
- **Label → `PinLabel`** — there IS a SwiftUI `PinLabel` (a themed `Text` convenience), because `Text(...).font(.body)` resolves to *Apple's* system style, not the provider font — a silent footgun the demos hit. `PinLabel("x").font(.caption)` (a themed `PinTextStyle`, not a raw `Font`) makes the system-font path unrepresentable. `.font(_:)` selects typography on both `PinLabel` and `PinButton`; `PinButton.style(_:)` is its visual variant (`.primary`/`.secondary`/…). It's a pure SwiftUI value (no hosting); UIKit keeps the independent trivial `UIKitPinLabel`. Both are fed by the same provider tokens.
  - **Rule of thumb — everything follows the theme.** All Pinwheel text must resolve provider-backed fonts/colors (`PinwheelTheme`), never Apple's system styles (`Font.body`, `.title`, `.foregroundStyle(.primary)`) which silently bypass the provider. Get there by whatever means fits: `PinLabel` for plain content text, or a component that applies the tokens itself (`PinButton`, `PinStateView`). Raw `Text` is fine only when something else already themes it — inside a component that owns its styling, or as a parameter to a *system* component that styles its own text (e.g. `ContentUnavailableView`'s description). A control's *label is still your content*: theme it (`Toggle(isOn:) { PinLabel("On") }`), don't pass a raw string.
- **Switch → `Toggle`** — no standalone `PinSwitch`; the only switch lives inside the UIKit `UIKitPinTableView` family.
- **DNA (Font / Color / Spacing)** — these are *tokens*, never components, in either world: `Config` providers → `UIColor`/`UIFont`/`CGFloat` extensions (UIKit) and `PinwheelTheme.Typography`/`Colors` + `.spacing*` (SwiftUI). Single source = the providers, which is why theming/light-dark resolves across the bridge for free.

**Modifier naming:** chained modifiers on our *own* types are unprefixed (`PinButton().style(.secondary)`, `PinItem().presentation(.medium)`); prefix with `pinwheel` *only* when extending a SwiftUI type to avoid collisions (`View.pinwheelTweaks { }`). Mirror SwiftUI's own names where one exists (`systemImage:`, `.font(_:)`).

This is separate from the **intentional UIKit surface** (`UIKitPinView` base, `UIKitPinFullscreenView`, the `UIKitPinTableView` family): those stay UIKit because of lifecycle / keyboard avoidance / cell recycling — not because a SwiftUI primitive suffices.

## Way of working

The mantra, so a fresh agent works the way we do from line one:

- **Theme is law.** Every Pinwheel surface resolves provider-backed tokens (`PinwheelTheme` / the `Config` providers), never Apple's system styles. When you add API, design it so the *wrong* (system-style) path is unrepresentable — that's why `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`. See the section above.
- **One implementation per component.** A bridgeable component is a SwiftUI `Pin*` source plus a thin `UIKitPin*` shell that hosts it — never two parallel implementations. Theming/light-dark crosses the bridge for free because both sides read the same provider tokens.
- **Shared vocabularies are top-level types.** When two or more components reuse a concept, promote it to a top-level `public` type instead of nesting it under one component (`PinTextStyle` for typography, `PinState` for content state, `PinLabel.TextColor` for color roles). No component should "own" what another reuses.
- **SwiftUI-native API.** Bare initializer + chained, themed modifiers (`PinLabel("x").font(.caption).color(.secondary)`, `PinButton("x") { }.style(.secondary).loading(flag)`). Mirror SwiftUI's own names where one exists (`systemImage:`, `.font(_:)`). `.style` is a button's visual variant; `.font` is typography on any text component. Raw escape hatches are explicit and named (`.color(.custom(...))`, `.style(.custom(text:background:))`). Modifier-prefix rule is in the section above.
- **Verify visually, don't assume.** After a UI change, *look* at it before saying it's done:
  - Render the permanent `#Preview` in `Demo/SwiftUIExamples/DemoPinwheelSections.swift` — set `previewComponentID` to the component's id and `mcp__xcode__RenderPreview` it. No throwaway `#Preview` needed.
  - Or deep-link a booted sim: `simctl launch <bundle> -PinwheelPreview <id> [-PinwheelPreviewTweak <title>]`.
  - `Scripts/preview-all.sh` snapshots every component and tweak variant to PNGs for a full sweep.
  - When the SwiftUI side must match the UIKit one, compare against the UIKit example (or `main`) — the UIKit rendering is the source of truth for parity.
- **Build/verify via the Xcode MCP.** `mcp__xcode__BuildProject` after every change, `RenderPreview` to look, `RunSomeTests`/`GetTestList` for the regression tests (`tabIdentifier: "windowtab1"`). Full details + the session-restart gotcha (MCP tools only register at session start with Xcode open on the project and Intelligence "Xcode Tools" on) live in the `xcode-mcp` skill (`.claude/skills/xcode-mcp/SKILL.md`); `xcodebuild`/`simctl` are the fallback.
- **Keep it green and current.** Builds stay warning-free. Update the docs/backlog (`docs/`) and the registry as components change. Commit in small, focused units with clean, minimal messages and push when a logical unit is done.

## Testing

`DemoUITests` are **regression tests**, not a coverage goal. Add a UI test when a real bug/regression surfaces in an interactive path (e.g. a tap that stopped firing) — write the test that would have caught it. We do **not** aim for full UI coverage; don't add speculative UI tests for paths that haven't broken.
