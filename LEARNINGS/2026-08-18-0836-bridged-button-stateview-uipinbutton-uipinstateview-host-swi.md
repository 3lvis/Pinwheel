**Bridged: Button, StateView.** `UIPinButton` / `UIPinStateView` host the SwiftUI implementation. Trade-off: one `UIHostingController` per instance — acceptable for these leaf/overlay components; revisit for dense reused contexts (e.g. table cells).
*— Elvis, 2026-08-18 08:36*
