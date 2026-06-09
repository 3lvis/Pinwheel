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
    /// Dismisses the presented component; the close button invokes this.
    var onClose: (() -> Void)?

    /// Badge count shown on the tweak (wrench) button.
    var tweakCount: Int { tweaks.count }

    /// The FAB shows only while a component is presented and the settings sheet
    /// is closed (so it never floats over the settings sheet itself).
    var isFloatingControlsVisible: Bool {
        isPresentingItem && !showsSettings
    }

    func selectSettings() { showsSettings = true }
    func selectClose() { onClose?() }
}
