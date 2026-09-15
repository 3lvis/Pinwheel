**`UIHostingController` already applies the bottom safe-area inset, so the chassis sets
`safeAreaRegions = []` and adds it once.** Leaving both to apply it measures it twice and leaves a
second inset of dead space under the content — 67pt below the commit button where the reference has 32.
*— Elvis, 2026-08-18 08:36*
