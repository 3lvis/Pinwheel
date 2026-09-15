**Every part is a coordinator or a value, and the name says which**

The tray began as one `UIView` called `PinTrayOverlay` that was, at once, the coordinator, the renderer,
the assembler, the measurer, the gesture reader, the body's delegate and the notification observer. It
reached 616 lines that way, and the reason it could is that *overlay* names a position rather than a job:
a name like that never objects to what you put in it.

Audited against "each part is a coordinator, or a value that only decides", five decisions turned out to
be living in the views that drew them — the backdrop's opacity, what counts as a resize, the clearance
above an accessory, which of a tray's two bottoms stands, and whether a move zooms. Each moved to the
value that owns it, and each became a test on the way.

What the split found, in the order it was found:

- **A tray's views are one picture, not three.** Faded separately, an accessory standing over a row lets
  the row through it. Measured on a white ground half way through a fade, that pixel reads 183 where one
  picture reads 247 — the row fades to grey first and then shows through, where a group covers it at full
  opacity and the finished picture fades once. Hence `PinTrayContentsView`.
- **A button that ends a flow outlives the tray that declared it.** It belongs to the card, which is what
  lets "the same button holds still" be a question about two trays rather than a comparison of two
  frames — an exact float equality standing in for identity.
- **The drag had two owners.** The body kept a running total of a pull while the machine kept another,
  seeded from it at the start of every gesture, and the two were different quantities: one raw finger
  travel, one rubber-banded. The body now reports the slice each frame gives it and holds nothing.
- **A lazy view touched during layout is a crash.** `layoutSubviews` runs while the tray is still being
  built, and it reaches for the card; as a `lazy var` that re-enters its own initialiser, which Swift
  does not survive — `signal segv` on every chassis test. It is a stored property built before the tray
  joins any hierarchy, joining its parent through `attach(to:)` afterwards, because a stored property
  cannot be handed `self`.

Two of those were found by measuring rather than reading, and one measurement was the wrong instrument
first: the compositing question was filmed for three rounds, chasing a moving crop, before being answered
exactly by rendering two views and reading one pixel. Compositing is deterministic; film is for motion.

The rule that came out of it: behaviour is a value with no views in it, and every part is named after
what it does.
*— Elvis, 2026-08-18 08:36*
