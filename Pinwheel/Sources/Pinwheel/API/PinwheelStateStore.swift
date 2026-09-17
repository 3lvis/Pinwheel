import SwiftUI
import UIKit

enum PinwheelStateStore {
    private static let selectedSectionIDKey = "Pinwheel.SelectedSectionID"
    private static let selectedItemIDKey = "Pinwheel.SelectedItemID"
    private static let selectedDeviceBySelectionKey = "Pinwheel.SelectedDeviceBySelection"
    private static let selectedThemeNameKey = "Pinwheel.SelectedThemeName"
    // Legacy key retained so the persisted FAB corner survives.
    private static let floatingControlsCornerKey = "lastCornerForTweakingButtonKey"

    static var selectedSectionID: String? {
        get { UserDefaults.standard.string(forKey: selectedSectionIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedSectionIDKey) }
    }

    static var selectedItemID: String? {
        get { UserDefaults.standard.string(forKey: selectedItemIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedItemIDKey) }
    }

    static var selectedThemeName: String? {
        get { UserDefaults.standard.string(forKey: selectedThemeNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedThemeNameKey) }
    }

    static var floatingControlsCorner: Int? {
        get { UserDefaults.standard.object(forKey: floatingControlsCornerKey) as? Int }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: floatingControlsCornerKey)
            } else {
                UserDefaults.standard.removeObject(forKey: floatingControlsCornerKey)
            }
        }
    }

    static func selectedDeviceIndex(for selection: PinwheelSelection) -> Int? {
        let values = UserDefaults.standard.dictionary(forKey: selectedDeviceBySelectionKey) as? [String: Int]
        return values?[selection.id]
    }

    // The store is the one place that names a UserDefaults key, and a setter keyed by the selection it
    // belongs to has no computed-property form.
    // oida:disable:next no_single_use_void_functions
    static func setSelectedDeviceIndex(_ deviceIndex: Int?, for selection: PinwheelSelection) {
        var values = UserDefaults.standard.dictionary(forKey: selectedDeviceBySelectionKey) as? [String: Int] ?? [:]
        values[selection.id] = deviceIndex
        UserDefaults.standard.set(values, forKey: selectedDeviceBySelectionKey)
    }
}
