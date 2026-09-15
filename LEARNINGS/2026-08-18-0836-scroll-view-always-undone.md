**A scroll view that is always on, and undone**

The first tray moved under a finger that had nothing to scroll. The body was scrollable at all times and
the delegate pinned the offset back whenever a pull went past the top — which cancels the *movement* and
leaves the *state* wrong, so the fix looked right on screen and was wrong everywhere a gesture asked the
scroll view whether it scrolls.

Turning it off properly took a second change nobody would predict from the first. The card's pan refused
every touch inside a `UIScrollView`, on the reasoning that a touch in the body belongs to the body — true
only while the body has somewhere to go. With scrolling off, the body stopped reporting pulls and the pan
still would not take the touch, so a downward drag on a fitting tray belonged to nobody and the tray
could not be dragged away at all. The pan now refuses only a scroll view that *can* scroll.

Two smaller traps came with it. Asking `contentSize` whether the content overflows answers stale during
layout, because the body is asked during the same pass that sizes the scroll view's content — ask what the
rows measure against the room there is instead, which has no ordering to get wrong. And the card was built
from the rows plus the body's *bottom* inset while the body also keeps a top one, so every tray sized to
fit its content was permanently scrollable by exactly that inset: 16 points of travel that read as a bug
in the bounce rather than in the measurement. The body reports what it needs now, insets included, and the
chassis stops adding either of them itself.
*— Elvis, 2026-08-18 08:36*
