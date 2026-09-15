**No tray ever covers the space that dismisses it.** Tapping the backdrop above the card dismisses the
whole tray, so `trayBackdropReach` reserves a strip of it — `.minimumControlHeight`, because tapping it
is a control and takes a control's target size. A filling tray taking *all* the room left 8pt between
the safe area and the card: measured, a tap aimed at that strip landed on the card instead, and the
header became the only way out. The room every tray is clamped to is now measured from below that
strip, which costs 40pt of height and buys back the affordance.
*— Elvis, 2026-08-18 08:36*
