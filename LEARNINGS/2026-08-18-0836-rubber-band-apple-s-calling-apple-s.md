**The rubber band is Apple's, and calling Apple's would buy nothing**

A tray resists a pull that has nowhere to go. A scroll view gives that for free and gives none of it
here — what has to move is the card rather than the list, and a tray whose rows already fit has no
scrolling to bounce.

UIKit does have the curve: dumping `UIScrollView` turns up
`_rubberBandOffsetForOffset:maxOffset:minOffset:range:outside:` and `_currentRubberBandCoefficient`,
among two dozen other rubber-band and bounce selectors. Called through its implementation pointer, the
coefficient reads 0.55 and the offset matches `(x·d·c) / (d + c·x)` to the penny at 10, 40, 100, 200, 400
and 4000 points of pull.

So the published formula is not an approximation of Apple's, it *is* Apple's, and the private call buys
nothing while putting a private selector into every app that links this library. Worth knowing which way
that argument ran: the reason to skip a private API here is that it was measured to be redundant, not
that it was assumed to be risky.

The tray passes its own `d` — a small allowance rather than the view's dimension, which is what Apple
passes — so however hard it is pulled the card stops short of the strip above it that dismisses it.
*— Elvis, 2026-08-18 08:36*
