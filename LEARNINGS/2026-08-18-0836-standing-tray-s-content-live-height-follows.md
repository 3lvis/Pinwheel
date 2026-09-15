**A standing tray's content is live, and its height follows.** The presenting view re-renders on its
own state, so an unchanged path still has to hand the standing tray freshly built content — without
that, a tray keeps rendering whatever it was mounted with, and a search field types into a list that
never filters (the same graph boundary that breaks `@FocusState`). The height then follows from
SwiftUI's side: the content is `.fixedSize(vertical:)` so it reports its *ideal* height rather than
the box it was put in, and an `onGeometryChange` hands that back to the chassis, which springs the
tray to it. Watching the hosted view's `intrinsicContentSize` from `layoutSubviews` does **not**
work — a required height constraint means nothing in the overlay's own layout is dirtied, so it
fires only at mount.
*— Elvis, 2026-08-18 08:36*
