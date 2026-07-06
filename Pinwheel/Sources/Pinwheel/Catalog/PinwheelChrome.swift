import SwiftUI

@MainActor
@Observable
final class PinwheelChrome {
    /// Held here rather than in the playground's `@State` so they survive
    /// playground re-renders / identity changes — the deep-link preview otherwise
    /// lost them when the settings sheet opened, leaving the sheet empty.
    var tweaks: [PinwheelTweak] = []
    var isPresentingItem: Bool = false
    var showsSettings: Bool = false
    var selectedDeviceIndex: Int?
    var onClose: (() -> Void)?
    // The displayed component, so the top pill can name it and show its capture version.
    var componentName: String?
    var componentID: String?
    // The preview variant (applied tweak), shown in the pill so a sweep snapshot names which one it is.
    var componentVariant: String?

    var tweakCount: Int { tweaks.count }

    var isFloatingControlsVisible: Bool {
        isPresentingItem && !showsSettings
    }

    var simulatedDevice: Device? {
        guard let selectedDeviceIndex, let device = Device.all[safe: selectedDeviceIndex], !device.isCurrent else {
            return nil
        }
        return device
    }

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
