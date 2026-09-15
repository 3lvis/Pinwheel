**The type scale is 20/18/16, taken from the reference.** `PinwheelDefaultFontProvider` was 23/20/17; measuring
X's tray gave an ~18pt semibold title, ~16pt body and row text, and a 20pt semibold price, which is a
cleaner three-step scale and is what the default theme now ships (footnote 13 and caption 11 unchanged).
`PinwheelFontProvider`'s semibold defaults hardcode their sizes rather than deriving them from the regular
variants, so a scale change has to be made in both files or the weights drift apart.
*— Elvis, 2026-08-31 09:35*
