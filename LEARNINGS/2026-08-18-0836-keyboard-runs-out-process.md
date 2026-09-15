**The keyboard runs out of process**

Its notifications are posted asynchronously, so anything driven off them is racing its animation — the
tray would always be a frame behind, or fighting. A constraint to `keyboardLayoutGuide` is carried *by*
that animation instead, which is why the card's bottom is pinned to the guide and nothing listens for a
frame. What the notifications are still read for is the duration and curve, which the keyboard announces
before it moves, so a tray leaving beside it can borrow the same clock.
*— Elvis, 2026-08-18 08:36*
