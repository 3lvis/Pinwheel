**`@FocusState` does not cross a hosting controller.** A tray's content renders in its own
`UIHostingController`, so focus declared on the presenting view silently never takes and the keyboard
never comes up; the field has to own its own `@FocusState` inside the tray's content. The symptom is
a text field that looks right, takes a tap to focus, and shows no caret on arrival.
*— Elvis, 2026-08-18 08:36*
