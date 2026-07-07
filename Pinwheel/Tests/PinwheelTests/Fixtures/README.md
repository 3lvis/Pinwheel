# apple-controls-v7-corruption.png

The six control crops from the corrupted Apple-controls capture (v7). Instead of the toggle,
segmented, slider, stepper, progress, and date-picker, they show **catalog rows**
("FullscreenView", "ViewController", "UIKit").

Cause: the capture was triggered from the catalog (the capture-on-view `autoPush` sink), so
`keyWindowControlCrops` cropped the *ambient* key window — the catalog — and assigned those crops
to the component's control leaves by vertical order.

Guard against recurrence: `PinDisplayListCapture.document(…, liveControlsOnScreen:)` defaults to
`false`, so the key window is cropped only when the caller vouches the component *is* the on-screen
content (the full-screen sweep). A capture-on-view from the catalog leaves it false, so no live
crops are taken and nothing foreign can land on a control. See `ControlCropMatchTests`.
