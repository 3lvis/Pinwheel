**Intentional UIKit surface (kept on purpose)**

These stay UIKit because no SwiftUI primitive matches their ergonomics/perf:

- **`UIPinView` base** — `setup()` lifecycle, open subclassing.
- **`UIPinFullscreenView`** — a base class for keyboard-aware full-screen screens (forms/editors): bottom-anchored content rides above the keyboard, plus a synthesized `viewDidFirstAppear()` hook. Kept UIKit and has **no SwiftUI demo on purpose** — SwiftUI gives keyboard avoidance and `onAppear` for free, so there's nothing to build; a SwiftUI "FullscreenView" example would only imply a component that shouldn't exist.
- **`UIPinTableView` family** — cell recycling, dataSource/delegate contract, `UISwitch` items, A–Z section indexer; no `List` equivalent with comparable perf.
*— Elvis, 2026-08-18 08:36*
