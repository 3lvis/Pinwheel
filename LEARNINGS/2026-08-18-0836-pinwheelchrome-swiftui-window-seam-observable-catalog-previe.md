**`PinwheelChrome` is the SwiftUI↔window seam** — an `@Observable` the catalog/preview owns and the window observes (tweaks, presented-state, settings visibility, selected device, close action). State lives here, not in playground `@State`, so the sheet, the playground resize, and the pill share one source of truth and survive re-renders.
*— Elvis, 2026-08-18 08:36*
