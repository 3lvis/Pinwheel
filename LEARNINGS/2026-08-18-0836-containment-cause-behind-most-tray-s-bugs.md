**Containment was the cause behind most of the tray's bugs**

The tray was built with SwiftUI holding the pieces and UIKit supplying the card around them. Nearly every
hard bug traced back to that one choice, and each was fixed locally until the list of local fixes became
the argument:

- Gestures fought across the seam. The card's pan and the list's own scrolling both wanted a downward
  drag, and neither could see the other, so ownership had to be arbitrated by a rule written twice.
- Children were findable only by walking somebody else's tree. Reaching the scroll view inside a hosted
  list meant a recursive `subviews` search for `UIScrollView`, which is a search that silently returns
  nothing the day SwiftUI changes what it builds.
- Content laid out against itself rather than against the card. An arriving tray measured its own fitting
  height and drew a search field at the middle of a card twice that tall, which was patched with
  `max(fittedHeight, geometry.height)` — a patch that only ever hid a structural mistake.
- A representable with no scene rendered nothing, so anything presented was unreachable from a test.

Moving containment to UIKit deleted all four rather than fixing them. The tray holds a title bar, a body
and an accessory as plain `UIView`s it constrains itself; SwiftUI supplies only leaves — a row, a title, a
field — hosted by `PinTrayLeafView`. The body owns its own scroll view outright, so
there is nothing to search for, the pan and the scroll are siblings under one owner, and every child is
laid out against the card because the card is what constrains it.

The rule that came out of it: SwiftUI is a leaf technology here. Anything that holds, lays out, scrolls
or routes a gesture is a `UIView` we own.
*— Elvis, 2026-08-18 08:36*
