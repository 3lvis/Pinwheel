# Agent Guidelines

- Treat Pinwheel as a SwiftUI-first package with UIKit compatibility.
- Do not add `import UIKit` to SwiftUI-first views, SwiftUI examples, or SwiftUI API call sites.
- Keep UIKit usage isolated to UIKit compatibility types, UIKit example components, or clearly named bridge/adaptor files that translate existing UIKit-backed providers into SwiftUI-native values.
- Prefer SwiftUI `Font`, `Color`, `View`, and environment-driven APIs for new package surfaces.

**Architecture decisions and their rationale live in [`docs/decisions.md`](docs/decisions.md)** — component surface, bridging, theme, the catalog/FAB, project layout, and the open follow-ups. This file is *how we work*; that file is *what we decided and why*. Read it before changing public API or structure.

## When to add a SwiftUI `Pin*` component

Add a `Pin*` (with its thin `UIKitPin*` shell) only when SwiftUI lacks a first-class primitive — so styling would be hand-rolled anyway (`PinButton`) — **or** there's real UIKit-hosting value to bridge (`PinStateView`). Otherwise use the SwiftUI primitive plus `PinwheelTheme` directly — **unless** the raw primitive silently bypasses the theme, which is exactly why `PinLabel` exists (raw `Text(...).font(.body)` resolves to *Apple's* system style, not the provider font). Full policy + rationale in `docs/decisions.md`.

**Modifier naming:** chained modifiers on our *own* types are unprefixed (`PinButton().style(.secondary)`, `PinItem().presentation(.medium)`); prefix with `pinwheel` *only* when extending a SwiftUI type to avoid collisions (`View.pinwheelTweaks { }`). Mirror SwiftUI's own names where one exists (`systemImage:`, `.font(_:)`). `.font` is typography on any text component; `.style` is a button's visual variant.

The **intentional UIKit surface** (`UIKitPinView` base, `UIKitPinFullscreenView`, the `UIKitPinTableView` family) stays UIKit on purpose — lifecycle / keyboard avoidance / cell recycling, not because a SwiftUI primitive is missing.

## Way of working

The mantra, so a fresh agent works the way we do from line one:

- **Theme is law.** Every Pinwheel surface resolves provider-backed tokens (`PinwheelTheme` / the `Config` providers), never Apple's system styles. When you add API, design it so the *wrong* (system-style) path is unrepresentable — that's why `PinLabel.font` takes a themed `PinTextStyle`, not a raw `Font`. See the section above.
- **One implementation per component.** A bridgeable component is a SwiftUI `Pin*` source plus a thin `UIKitPin*` shell that hosts it — never two parallel implementations. Theming/light-dark crosses the bridge for free because both sides read the same provider tokens.
- **Shared vocabularies are top-level types.** When two or more components reuse a concept, promote it to a top-level `public` type instead of nesting it under one component (`PinTextStyle` for typography, `PinState` for content state, `PinLabel.TextColor` for color roles). No component should "own" what another reuses.
- **SwiftUI-native API.** Bare initializer + chained, themed modifiers (`PinLabel("x").font(.caption).color(.secondary)`, `PinButton("x") { }.style(.secondary).loading(flag)`). Mirror SwiftUI's own names where one exists (`systemImage:`, `.font(_:)`). `.style` is a button's visual variant; `.font` is typography on any text component. Raw escape hatches are explicit and named (`.color(.custom(...))`, `.style(.custom(text:background:))`). Modifier-prefix rule is in the section above.
- **Verify visually, don't assume.** After a UI change, *look* at it before saying it's done:
  - Render the permanent `#Preview` in `Demo/Examples/SwiftUI/DemoPinwheelSections.swift` — set `previewComponentID` to the component's id and `mcp__xcode__RenderPreview` it. No throwaway `#Preview` needed.
  - Or deep-link a booted sim: `simctl launch <bundle> -PinwheelPreview <id> [-PinwheelPreviewTweak <title>]`.
  - `Scripts/preview-all.sh` snapshots every component and tweak variant to PNGs for a full sweep.
  - When the SwiftUI side must match the UIKit one, compare against the UIKit example (or `main`) — the UIKit rendering is the source of truth for parity.
- **Build/verify via the Xcode MCP.** `mcp__xcode__BuildProject` after every change, `RenderPreview` to look, `RunSomeTests`/`GetTestList` for the regression tests (`tabIdentifier: "windowtab1"`). Full details + the session-restart gotcha (MCP tools only register at session start with Xcode open on the project and Intelligence "Xcode Tools" on) live in the `xcode-mcp` skill (`.claude/skills/xcode-mcp/SKILL.md`); `xcodebuild`/`simctl` are the fallback.
- **Keep it green and current.** Builds stay warning-free. Update `docs/decisions.md` (decisions + open follow-ups) and the registry as components change. Commit in small, focused units with clean, minimal messages and push when a logical unit is done.

## Testing

`DemoUITests` are **regression tests**, not a coverage goal. Add a UI test when a real bug/regression surfaces in an interactive path (e.g. a tap that stopped firing) — write the test that would have caught it. We do **not** aim for full UI coverage; don't add speculative UI tests for paths that haven't broken.
