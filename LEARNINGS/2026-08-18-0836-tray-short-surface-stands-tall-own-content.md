**A tray is a short surface that stands as tall as its own content, and a sequence of them is one
surface changing.** `PinTray` is the content — centred title, one leading control, optional trailing
accessory, optional commit — and `View.pinwheelTray(path:)` is the stack, where the array *is* the
navigation: appending pushes, removing pops. The leading control is **derived from depth**, a cross at
the root and a back chevron once pushed, so a root tray showing "back" is unrepresentable. Modelled on
the tray system Benji Taylor built for Family and now X, whose published rules we follow: one piece of
content or one action per tray, every tray titled, consecutive trays differing in height, and the theme
taken from context.
*— Elvis, 2026-08-18 08:36*
