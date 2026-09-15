**One implementation per bridgeable component.** A `Pin*` SwiftUI source plus a thin `UIPin*` shell that hosts it (via `PinHostView`), never two parallel reimplementations. Theming, light/dark, and Dynamic Type cross the bridge for free because both worlds read the same theme providers.
*— Elvis, 2026-08-31 09:35*
