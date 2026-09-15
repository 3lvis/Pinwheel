**A search tray is header, rule, scrolling list, and a search field floating over the list at the
bottom.** The field sits where the thumb is and never scrolls away, the list runs on underneath it
(`.contentMargins(.bottom,)` so the last row is still reachable), and `.scrollDismissesKeyboard(.interactively)`
gives the keyboard back to a downward drag. A tray declares that it fills through `PinTrayFillsKey`,
and the room it currently has arrives on the observable `PinTrayPhase` — not the environment, so the
keyboard moving re-renders the content without rebuilding it.
*— Elvis, 2026-08-18 08:36*
