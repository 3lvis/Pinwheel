import SwiftUI
import UIKit

public nonisolated struct PinwheelThemeTrait: UITraitDefinition {
    public static let defaultValue = PinwheelTheme.standard
    public static let affectsColorAppearance = true
}

nonisolated struct PinwheelThemeKey: EnvironmentKey {
    static let defaultValue = PinwheelTheme.standard
}

extension PinwheelThemeKey: UITraitBridgedEnvironmentKey {
    static func read(from traitCollection: UITraitCollection) -> PinwheelTheme {
        traitCollection[PinwheelThemeTrait.self]
    }

    static func write(to mutableTraits: inout UIMutableTraits, value: PinwheelTheme) {
        mutableTraits[PinwheelThemeTrait.self] = value
    }
}

public extension EnvironmentValues {
    var pinwheelTheme: PinwheelTheme {
        get { self[PinwheelThemeKey.self] }
        set { self[PinwheelThemeKey.self] = newValue }
    }
}
