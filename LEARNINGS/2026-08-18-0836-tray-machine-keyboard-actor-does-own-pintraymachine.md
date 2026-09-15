**The tray is a machine, and the keyboard is an actor it does not own.** `PinTrayMachine` holds the
state — what the tray holds, what the keyboard is doing, whether the standing tray edits, a drag —
and answers each event with where the tray goes *and who moves it there*. That last part is the one
every bug turned on, so `Timeline` is state: `.immediate` for an entry position or a finger,
`.spring(bounce:)` for a change nothing else owns, and `.carriedByKeyboard` for one the keyboard owns,
where we set the value and start nothing. The keyboard enters as **reports** (`closed`, `opening`,
`open`, `closing`) mapped from the guide rather than as something we command, because we cannot
command it — and `opening`/`closing` are exactly the states in which it owns the timeline. Effects it
cannot perform itself, like dismissing the keyboard on the way out, come back as `Effect` values.
Every rule is then a test with no window: twelve of them, each named for the state that broke.
*— Elvis, 2026-08-18 08:36*
