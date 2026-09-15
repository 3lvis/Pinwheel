**A tray's shape arrives as state, never as its own animation.** Wiring `fills` up from the tray's
preference, its `didSet` also drew the change — `settleGeometry(animated:)`, a second animation path
the machine knew nothing about. It fired when the preference landed, which is *before* the keyboard,
so the card grew to the floor and then climbed back: measured, the top went 262 → 602 → 76, one
reversal and 340pt of wasted downward travel, which is exactly the shoot the awaiting-keyboard hold
exists to prevent. The flag is now only recorded and the next event carries it; the same run then
reads 262 → 76, monotonic, no reversal. Any `didSet` that draws is this bug again.
*— Elvis, 2026-08-18 08:36*
