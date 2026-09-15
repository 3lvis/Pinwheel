**A tray leaves on the keyboard's clock, not after it.** Tapping the space above an editing tray
dismisses the whole tray — one meaning per control, and backing out of a sheet should not depend on
which part of the backdrop was hit. Its motion used to be three reactions fighting inside 24ms: the
keyboard's report said *rest*, the dismissal said *leave* against a keyboard already sent away, and a
second report said *rest* again and won — so the card lurched two thirds of the way down and was
deleted off the screen mid-air (measured: top 103 → 445 of 912, removed at 0.335s). Now leaving is
sticky (a report cannot put a leaving tray back), the exit is measured with the keyboard gone, and it
is drawn on the duration and curve the keyboard announces in `keyboardWillShow`/`Hide` — so the two
start together and stay on one curve instead of handing off, which is where a stall comes from. The
keyboard's real duration is **0.3833s**, not the 0.25s everyone assumes: borrow the clock, never guess
it. `PinTrayMachine.Timeline.matching` carries it, and the unmount waits for that same duration.
*— Elvis, 2026-08-18 08:36*
