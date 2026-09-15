**The keyboard is measured from the edge the card is pinned to, and the margin above it comes from one
place.** The card's bottom is a constraint to `keyboardLayoutGuide`; its height is the machine's. Two
disagreements between them left the top drifting 26pt as the keyboard went, which reads as the card
sliding down while you scroll. First, `measuredKeyboardHeight` subtracted the bottom safe area that the
guide already excludes (`usesBottomSafeArea` is false), so the machine believed a 345pt keyboard was
311 and made the card 26pt too tall. Second, one constraint serves both a docked keyboard and no
keyboard at all, so a fixed margin on it is right for one and wrong by 8 for the other — `offset.constant`
is now whatever the geometry keeps clear beyond the keyboard itself. Measured with a live keyboard,
the top went 90 → 124 → 116, where 116 is `safeAreaTop + trayBackdropReach` and is what the model said
all along. Teeth: reverting both puts it back to 90 on the same probe.
*— Elvis, 2026-08-18 08:36*
