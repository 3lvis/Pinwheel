**Who a downward drag belongs to**

Dragging down from the top of the results, the list rubber-banded over nothing, and then snapped back to
rest the moment the finger reached the bottom of the card and the keyboard began to go. Two things
fighting: the list's own bounce, and the card's dismissal.

There is nothing above the first result, so a downward drag there has nothing to reveal — it belongs to
the card. `PinTrayMachine.cardTakesTheDrag` is the whole rule and is pure: the card takes it when the
list is at its top and the finger is moving down, and once it has a gesture it keeps it to the end,
because a drag that changed hands half way would stop dead under the finger.

The chassis makes that work by watching *alongside* the list rather than instead of it — the card's pan
recogniser returns true from `shouldRecognizeSimultaneouslyWith`, so neither wins the gesture outright and
ownership is decided per movement. While the card has it the list is pinned to its top, or it
rubber-bands underneath and snaps back exactly as before.

The rejected alternative was letting the list bounce and animating it back at the handover, which is two
motions where there should be one.
*— Elvis, 2026-08-18 08:36*
