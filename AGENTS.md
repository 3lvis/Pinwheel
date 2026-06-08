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
- **Label → `PinLabel`** — there IS a SwiftUI `PinLabel` (a themed `Text` convenience), because `Text(...).font(.body)` resolves to *Apple's* system style, not the provider font — a silent footgun the demos hit. `PinLabel("x", style: .body)` makes the system-font path unrepresentable. It's a pure SwiftUI value (no hosting); UIKit keeps the independent trivial `UIKitPinLabel`. Both are fed by the same provider tokens.
  - **Rule of thumb:** use `PinLabel` for content text; keep raw `Text` only inside a component that owns its own styling (e.g. `PinButton`'s label) or as a parameter to a system component that styles its own content (e.g. `ContentUnavailableView`, `Toggle` labels).
- **Switch → `Toggle`** — no standalone `PinSwitch`; the only switch lives inside the UIKit `UIKitPinTableView` family.
- **DNA (Font / Color / Spacing)** — these are *tokens*, never components, in either world: `Config` providers → `UIColor`/`UIFont`/`CGFloat` extensions (UIKit) and `PinwheelTheme.Typography`/`Colors` + `.spacing*` (SwiftUI). Single source = the providers, which is why theming/light-dark resolves across the bridge for free.

This is separate from the **intentional UIKit surface** (`UIKitPinView` base, `UIKitPinFullscreenView`, the `UIKitPinTableView` family): those stay UIKit because of lifecycle / keyboard avoidance / cell recycling — not because a SwiftUI primitive suffices.
