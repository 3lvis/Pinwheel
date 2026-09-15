**The tray's bottom clearance is the home indicator's, not a spacing token.** It reads as 24pt on an
iPhone Air, which is the bottom safe area less the margin the card already stands off the screen by —
so the tray derives it (`safeAreaInsets.bottom - trayBottomMargin`, floored at `.spacingL`) and the
content's bottom lands exactly on the safe-area boundary on any device. Lifted onto the keyboard
there is no indicator to clear, so it drops to the floor. Hardcoding 24 would be right on one phone.
*— Elvis, 2026-08-18 08:36*
