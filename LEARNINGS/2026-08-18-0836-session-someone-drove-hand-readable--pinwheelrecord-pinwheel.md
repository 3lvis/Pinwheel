**A session someone drove by hand is readable: `-PinwheelRecord`.** `PinwheelRecorder` writes
`session.log` into the app's temporary directory — every touch with the identifier of whatever it hit,
every navigation, everything SwiftUI reports in, every reaction the machine returns, and the geometry
between them (only when it changes, so sitting still costs nothing to read). Touches come from a
`UIGestureRecognizer` that never leaves `.possible`, so it sees everything and swallows nothing; it
attaches to each window on `didBecomeVisibleNotification`. Off entirely without the argument. It exists
so a person can say "watch this" instead of describing it — and because a description of motion is the
thing this repo keeps proving you cannot act on. **Each launch truncates the file**, so read it before
relaunching.
*— Elvis, 2026-08-18 08:36*
