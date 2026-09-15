**An effect the machine commands counts as having happened, that same turn.** Coming back from the
search tray landed the card at 509pt — a height belonging to neither tray. The reaction was computed
while the keyboard was still up and applied *after* `endEditing` had already re-laid the screen, so the
keyboard's own reports landed first and the stale answer overwrote them. Dismissing is therefore a
change to the machine's own state (`keyboard = .closing`) at the moment it is ordered, not when the
keyboard gets around to confirming it — which makes the outside world's confirmation agree with what we
already drew, so arrival order stops mattering. Two tests hold it, one for the height and one for the
ordering.
*— Elvis, 2026-08-18 08:36*
