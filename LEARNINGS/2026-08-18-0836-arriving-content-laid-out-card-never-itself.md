**The arriving content is laid out to the card, never to itself.** The chassis mounted an arriving
tray at its own measured height and `write` kept re-setting it there — 245 inside a 642 card — so the
search field, which rides the content's bottom edge, appeared mid-card and travelled down once the move
resolved. The card's own geometry was clean throughout, which is why every tape of the *card* said the
push was fine: 794pt of field travel, invisible in the column being sampled. `currentHeight` is now
`max(fittedHeight, geometry.height)` — taller than its card it keeps its height and scrolls, shorter it
stretches to fill — and the field's bottom edge no longer moves at all during a push. `settleGeometry`,
a second place that drew the same constant and had no callers left, is gone with it.
*— Elvis, 2026-08-18 08:36*
