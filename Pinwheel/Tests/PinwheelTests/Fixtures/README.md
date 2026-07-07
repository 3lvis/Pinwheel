# apple-controls-v7-corruption.png

The six control crops from the corrupted Apple-controls capture (v7). Instead of the toggle,
segmented, slider, stepper, progress, and date-picker, they show **catalog rows**
("FullscreenView", "ViewController", "UIKit").

Cause: the capture was triggered from the catalog (the capture-on-view `autoPush` sink), so
`keyWindowControlCrops` cropped the *ambient* key window — the catalog — and assigned those crops
to the component's control leaves by blind vertical order (the `count == count` guard passed, 6 == 6).

Guard against recurrence: `PinDisplayList.matchedControlCrops` now pairs a leaf with a live crop only
when the crop rendered at that leaf's position (frame + safe-area inset). A control from another
on-screen surface doesn't line up, so it's left unmatched and the leaf falls back to the safe
host-layer crop instead of foreign content. See `testControlCropsRejectForeignPositionedControls`.
