**`viewController:` items follow the same rule** — both `PinwheelItem(_:viewController:)` inits build the controller once and bridge `Tweakable` (reading its `tweaks` into the playground), mirroring `view:`. A `UIViewController` that conforms to `Tweakable` gets its tweaks in the settings sheet, and they drive the live (on-screen) instance — not an off-screen copy.
*— Elvis, 2026-08-18 08:36*
