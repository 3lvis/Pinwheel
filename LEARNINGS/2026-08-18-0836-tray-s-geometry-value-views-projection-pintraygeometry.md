**The tray's geometry is a value, and the views are a projection of it.** `PinTrayGeometry` takes
what the tray holds, the room, the keyboard, a drag and a phase, and answers height, clearance,
translation and corner — importing `CoreGraphics` and nothing else. Every rule discovered by filming
the reference is a plain test there (12 of them, 8ms, no window), and the chassis reads it in one
place and applies it in one closure. The bug that forced this: a transform assigned before the
animation rather than inside it, so a tray arrived already in place — invisible to every test, and
only findable by asserting on a `CALayer` animation key, which is testing the mechanism. With the
geometry extracted, "a tray arrives from below its own bottom edge" is a value comparison, and the
one place that applies it can no longer put half the state outside the animation.
*— Elvis, 2026-08-18 08:36*
