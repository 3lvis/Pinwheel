**Asking whether a keyboard will appear, and failing twice**

A tray sized by what it holds must stand still when it is about to raise a keyboard, or it shrinks to the
floor and climbs back. The hold needs to know a keyboard is actually coming, and two private answers were
tried against a simulator where the software keyboard demonstrably appears:

- `GSEventIsHardwareKeyboardAttached()` returned **true**, and the software keyboard appeared anyway.
  Attached and shown are independent — a hardware keyboard can be connected with the software one toggled
  on over it.
- `+[UIKeyboard isInHardwareKeyboardMode]`, which is what UIKit itself consults and which *should* mean
  "attached and the software keyboard suppressed", also returned **true** while a 345pt keyboard was on
  screen and `keyboardWillShow` reported its top at 567.

Both answers were recorded beside the keyboard that contradicted them. Believing either put the card on
the floor with the keyboard covering its own search field.

Then the runtime was dumped rather than read about: every BOOL property on `UIKeyboardImpl` — forty of
them — plus both class answers and the text-effects window, captured twice, at focus before any keyboard
and again when `keyboardWillShow` fired. **Every value was identical between the two.** Nothing the
runtime exposes moves when a keyboard appears, so there is nothing to predict with.

The dump also explains both failures: `isInHardwareKeyboardMode` does not mean "no keyboard will appear",
it means a hardware keyboard is in use — and the software keyboard can be shown alongside one, which is
exactly this simulator. Read as mutually exclusive it is simply the wrong flag.

What does change is the keyboard's geometry, which `keyboardLayoutGuide` already reports, publicly, and
which the tray is already laid out by.

There is no prediction here worth having, so none is made: `edits` means focus, and the hold is guarded
by the thing that actually removes the need for it — a filling tray is sized by the room, so its top does
not move when the keyboard arrives and it never has to wait. Every tray in the app fills. If one that
does not ever needs the hold, the signal to resolve it should be an event that has already proved
reliable — `keyboardWillShow`, or the guide moving — never a timeout, and never one of these two flags.
*— Elvis, 2026-08-18 08:36*
