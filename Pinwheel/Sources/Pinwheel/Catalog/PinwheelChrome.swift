import SwiftUI

extension SwiftUI.View {
    // A presentation is a new SwiftUI root: it inherits neither the chrome, the theme nor the
    // color scheme from the view it is attached to.
    func pinwheelPresented(_ chrome: PinwheelChrome) -> some SwiftUI.View {
        environment(chrome)
            .environment(\.pinwheelTheme, chrome.theme)
            .preferredColorScheme(chrome.colorScheme)
    }
}

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
    var componentName: String?
    var componentID: String?
    var componentVariant: String?
    var colorScheme: ColorScheme?
    var themes: [PinwheelTheme] = [.standard]
    var selectedThemeName: String?

    var tweakCount: Int { tweaks.count }

    var theme: PinwheelTheme {
        themes.first { $0.name == selectedThemeName } ?? themes.first ?? .standard
    }

    var isThemePickerVisible: Bool { themes.count > 1 }

    func selectTheme(_ theme: PinwheelTheme) {
        selectedThemeName = theme.name
        PinwheelStateStore.selectedThemeName = theme.name
    }

    func normalizeTheme() {
        if let selectedThemeName, themes.contains(where: { $0.name == selectedThemeName }) { return }
        selectedThemeName = themes.first?.name
    }

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
