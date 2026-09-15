**Where the tray's borrowed numbers come from**

Nothing in the source says whose these are, so it is written here once.

- `trayRubberBanding` = **0.55**, `trayDecelerationRate` = **0.99**, `trayThrowSpeed` = **250**. All three
  are UIKit's own, read at runtime off the `_UIHyperInteractor` ivars its sheets hand a drag to —
  `__rubberBandCoefficient`, `__decelerationRate` (factor 99) and `__minimumSpeed`. The rate is also
  `UIScrollView`'s `.fast`.
- The rubber-band curve is Apple's exactly: `(x·d·c) / (d + c·x)`, checked against
  `-[UIScrollView _rubberBandOffsetForOffset:maxOffset:minOffset:range:outside:]` and equal to the penny
  at every pull. It diverges in `d` alone — Apple passes the view's own dimension, a tray passes
  `trayLift`, which is what keeps the strip above the card reachable however hard it is pulled.
- `trayResizeDuration` = 0.30 and `trayResizeBounce` = 0.10 come off the reference capture, not taste.
*— Elvis, 2026-08-18 08:36*
