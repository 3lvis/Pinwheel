**The chassis is hand-written UIKit hosting SwiftUI, because neither `presentationDetents` nor
`UIPresentationController` will give up the height.** A detent is a declared *set of stops* that UIKit
re-resolves with its own animation, so the sheet edge can't be put on the same timeline as the content;
and a presentation controller re-applies `frameOfPresentedViewInContainerView` on the next layout pass,
which cancels a spring started against it. The tray therefore owns everything: its own view in the
topmost controller's hierarchy, a height constraint, a dimming view, and one
`UIView.animate(springDuration:bounce:)` driving the height and the cross-dissolve together.
*— Elvis, 2026-08-18 08:36*
