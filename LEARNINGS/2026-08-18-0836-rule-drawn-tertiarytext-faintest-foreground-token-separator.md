**A rule is drawn in `tertiaryText`, the faintest foreground token — a separator is not its own
token.** The palette is nine role tokens and stays nine: adding a `divider` beside them would be a
token per use, which is a list of colours rather than a system. `secondaryBackground` (242 on white)
was too faint to read at 1pt, so the hairline in `PinTray` and
`UIPinTableView`'s `separatorColor` all take `tertiaryText`. One rule colour, already in the
vocabulary.
*— Elvis, 2026-08-18 08:36*
