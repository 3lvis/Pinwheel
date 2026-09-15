**A tray is as tall as what it holds, or as tall as the room there is — `.fitting` or `.filling`.**
`.medium` was a lie once it stopped being half of anything, so the pair now says what it means. A
filling tray is anchored by its **top**, which makes that top a constant (`safeAreaTop + trayMargin`)
no keyboard can move: only the bottom travels, riding the keyboard down and clamping at the floor
while the keyboard carries on past it. That is what stops the card shooting when the search field is
tapped again — it is structural, not arranged. Guarded by
`testAFillingTrayKeepsItsTopWhereverTheKeyboardIs`, which sweeps the keyboard 311 → 0 → 311 and asserts
one distinct top; with the anchor removed it walks 585 → 904 → 585.
*— Elvis, 2026-08-18 08:36*
