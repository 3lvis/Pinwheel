**A tray about to edit hands its timeline to the keyboard; one that is leaving dismisses it
deliberately.** Two faults with one cause — geometry resolved at a moment when the keyboard's state
was not yet true. Pushing to a tray that edits, the card shrank to its new height with no keyboard
under it yet, so its top fell 184pt to the floor and climbed back once the keyboard arrived. So the
push now waits a turn, asks whether anything in the tray became first responder, and if so leaves the
height for the keyboard to carry: the constant is set from `layoutSubviews` when the guide moves, so
it resolves inside the keyboard's animation. Measured, the top then runs 262 -> 103 without ever
reversing. Popping, unmounting the tray tore the field out from under the keyboard and it vanished
with no animation to travel with, so the card descended alone; `endEditing(true)` before the
transition gives the keyboard its own dismissal to ride, and the card goes 103 -> 262 beside it.
The dissolve stays on its own timeline in both directions — it is the content changing, not the card
moving, and it should never wait on a keyboard.
*— Elvis, 2026-08-18 08:36*
