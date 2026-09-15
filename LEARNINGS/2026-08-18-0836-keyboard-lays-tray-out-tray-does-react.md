**The keyboard lays the tray out; the tray does not react to the keyboard.** On iOS 17+ the keyboard
runs in its own process and "will *asynchronously* initialize the keyboard UI and then
*asynchronously* post the notifications and perform the animations" (WWDC23, *Keep up with the
keyboard*) — so anything driven off `keyboardWillChangeFrame` is racing an animation it cannot join,
which is why our own spring read as staggered no matter how it was tuned. The tray constrains its
bottom to `keyboardLayoutGuide.topAnchor` with `usesBottomSafeArea = false`, and hands the two
margins to `setConstraints(_:activeWhenNearEdge:)` / `activeWhenAwayFrom:` so UIKit swaps them inside
the keyboard's own animation. Interactive dismissal comes free — the guide tracks the dismiss gesture.
**Never toggle those constraints by hand from `layoutSubviews`**: it re-enters layout and UIKit throws
`_setActive:mutuallyExclusiveConstraints:`. Only the corner radius is read there, because a corner is
not expressible as a constraint.
*— Elvis, 2026-08-18 08:36*
