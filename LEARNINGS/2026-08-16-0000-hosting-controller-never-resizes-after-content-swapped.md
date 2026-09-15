**A hosting controller that never resizes after its content is swapped**

`PinTrayBodyView` shows a SwiftUI list through a `UIHostingController` inside a scroll view. Building it
that way works, and swapping its content afterwards does not: the hosting view keeps the height the *old*
content had, so a 60-row list laid out 20 points tall. The scroll view then had nothing to scroll and
nothing to be pulled past, which is why pull-to-dismiss recorded zero frames — and, in a UI test, why every
row answered `Not hittable` while sitting in the accessibility tree at full strength.

The fix is one line, `hosting.sizingOptions = .intrinsicContentSize`, which is what makes the controller
report what SwiftUI drew as its view's own size on every subsequent pass.

What cost the time was the observable, not the fix. Three plausible assertions were green with the bug in
place: the scroll's content height *at build time*, the same height under Auto Layout in a window, and the
height after a first layout at zero width. Measuring also stayed correct throughout — `contentHeight(fitting:)`
asks SwiftUI with `sizeThatFits` and never consults the hosting view — so the tray sized itself right while
holding rows nobody could touch. Only `show(_:)` *after* the body is standing reproduces it, because only
then is there a previous size to keep. `testRowsShownAfterAttachAreLaidOutAsTallAsTheyMeasure` goes red at
20.3 against 1220.

The general shape: when a hostless test stays green against a bug the app plainly has, the configuration is
wrong rather than the rung. Reach for the app to confirm the bug is still real — the `Not hittable` failure
is what proved the attribution — then keep narrowing the test until it reproduces, and throw away the
assertions that were never red.

*— Elvis, 2026-08-16*
