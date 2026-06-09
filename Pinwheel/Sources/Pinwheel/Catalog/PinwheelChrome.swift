import SwiftUI

/// The seam between the SwiftUI catalog/preview and the floating tweak/close
/// controls (a UIKit `CornerAnchoringView` hosted in a pass-through overlay
/// window — see `PinwheelFloatingControlsHost`).
///
/// The controls live in a separate `UIWindow` so they float *above* sheet
/// presentations and never clip to (or clash with) the presented content. The
/// SwiftUI side only reads/writes this coordinator; the window observes it.
@MainActor
@Observable
final class PinwheelChrome {
    /// The presented component's tweaks. Held here (a persistent reference) rather
    /// than in the playground's `@State` so they survive playground re-renders /
    /// identity changes — the deep-link preview otherwise lost them when the
    /// settings sheet opened, leaving the sheet empty.
    var tweaks: [PinwheelTweak] = []
    /// Whether a component is currently presented — gates the FAB's visibility.
    var isPresentingItem: Bool = false
    /// Drives the SwiftUI settings sheet; the wrench button sets this `true`.
    var showsSettings: Bool = false
    /// The simulated device index into `Device.all`, or nil for the real device.
    /// Held here so the settings sheet, the playground resize, and the floating
    /// device pill share one source of truth.
    var selectedDeviceIndex: Int?
    /// Dismisses the presented component; the close button invokes this.
    var onClose: (() -> Void)?

    /// Badge count shown on the tweak (wrench) button.
    var tweakCount: Int { tweaks.count }

    /// The FAB shows only while a component is presented and the settings sheet
    /// is closed (so it never floats over the settings sheet itself).
    var isFloatingControlsVisible: Bool {
        isPresentingItem && !showsSettings
    }

    /// The simulated device — set, and not the real device. nil means "no
    /// simulation" (real device), which the pill treats as nothing to show.
    var simulatedDevice: Device? {
        guard let selectedDeviceIndex, let device = Device.all[safe: selectedDeviceIndex], !device.isCurrent else {
            return nil
        }
        return device
    }

    /// The device pill shows whenever a non-current device is simulated — even
    /// while the settings sheet is open (so you can see the active device while
    /// picking) and after it's dismissed.
    var isDevicePillVisible: Bool {
        isPresentingItem && simulatedDevice != nil
    }

    func selectSettings() { showsSettings = true }

    /// Hide the controls immediately so the FAB and device pill dismiss in sync
    /// with the close, instead of lingering until the dismissal animation ends.
    func selectClose() {
        isPresentingItem = false
        onClose?()
    }
}
