**Waiting for a keyboard that is not coming**

A tray that will raise a keyboard holds still until it moves, so a shrinking card does not drop to the
floor and climb back. That hold is a bet, and with a hardware keyboard attached it never settles: the
field takes focus and nothing rises, so the tray sat at its content's height — 245 of a possible 834 —
for as long as it was open.

The first answer was a stopwatch on the bet, `trayKeyboardGrace`, which is a guess about the world
dressed as a timeout, and behaviour behind a delay. `GSEventIsHardwareKeyboardAttached` in
GraphicsServices answers the question outright, so `PinTrayKeyboardPresence` asks it and `edits` means
"will raise a keyboard" rather than "has focus". Private, looked up by name, absent means no hardware
keyboard — the same answer the simulator gives with one disconnected.

The other half is that a filling tray never needed to wait at all: it is sized by the room, so its top is
the same before and after the keyboard arrives and there is no dip available to it. With both, nothing in
the tray waits on a clock, and the tear-down that used to be a timer beside the exit animation is that
animation's own completion.
*— Elvis, 2026-08-18 08:36*
