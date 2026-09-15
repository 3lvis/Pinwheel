**The card's bottom corners take the display's own radius, and the top pair does not.** A
bottom-anchored card reads as continuous with the hardware only when its bottom corners carry the
screen's radius outright — `UIScreen`'s `_displayCornerRadius` (62 on an iPhone Air), read by KVC
since UIKit exposes it nowhere public. Note it is *not* the concentric `radius - inset`: 54 was
measurably too tight, and matching the reference's corner profile point by point picked 62. The top
corners sit nowhere near a device corner and stay small (28). `CALayer` carries one radius, so the
card is two nested layers — an outer rounding only the bottom pair, an inner rounding only the top —
which keeps both animating natively with the height, where a `CAShapeLayer` mask would have to be
animated by hand. Both set `cornerCurve = .continuous`, matching `ConcentricRounding`'s existing
vocabulary; a circular corner reads as cut against the device's curve.
*— Elvis, 2026-08-18 08:36*
