**A UIKit collection sits below the safe-area inset; lift the capture to the top.** The table's first cell starts ~62pt down (the safe-area content inset), a gap the SwiftUI capture already trims. `PinUIKitListCapture` shifts the whole list up by the first row's offset so content begins at the top, matching the SwiftUI side.
*— Elvis, 2026-08-18 08:36*
