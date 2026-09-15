**A card standing clear of the bottom edge loses the display's radius.** With the keyboard up the
tray rides above it, is no longer nested in the display's corner, and its bottom pair drops to the
same radius as its top — measured on the reference, the two corners are then identical. The overlay
watches `keyboardWillChangeFrame`, lifts by the overlap, and animates the corner with the keyboard's
own duration and curve so the two move as one.
*— Elvis, 2026-08-18 08:36*
