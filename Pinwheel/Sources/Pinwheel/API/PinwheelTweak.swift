import SwiftUI

@resultBuilder
public enum PinwheelTweakBuilder {
    public static func buildBlock(_ components: PinwheelTweak...) -> [PinwheelTweak] {
        return components
    }

    public static func buildArray(_ components: [[PinwheelTweak]]) -> [PinwheelTweak] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [PinwheelTweak]?) -> [PinwheelTweak] {
        return component ?? []
    }

    public static func buildEither(first component: [PinwheelTweak]) -> [PinwheelTweak] {
        return component
    }

    public static func buildEither(second component: [PinwheelTweak]) -> [PinwheelTweak] {
        return component
    }
}

public struct PinwheelTweak: Identifiable, Equatable {
    enum Control {
        case action(() -> Void)
        case toggle(Binding<Bool>)
        case select(options: [String], selection: Binding<Int>)
    }

    public let id: String
    public let title: String
    public let description: String?
    let control: Control

    /// Preferences are compared by value and `onPreferenceChange` fires only on inequality, so equality
    /// reads the choice as it stood when this value was built: reading the binding at comparison time
    /// reports the same answer for both generations and the tray keeps drawing the older row.
    let chosenOptionWhenBuilt: Int?

    /// A UIKit host builds its bridged tweaks once, so the option in force is read from the binding
    /// rather than from what this value was built with.
    var selectedOption: Int? {
        guard case .select(_, let selection) = control else { return nil }
        return selection.wrappedValue
    }

    public init(_ title: String, id: String? = nil, description: String? = nil, action: @escaping () -> Void) {
        self.id = id ?? title
        self.title = title
        self.description = description
        self.control = .action(action)
        self.chosenOptionWhenBuilt = nil
    }

    public init(_ title: String, id: String? = nil, description: String? = nil, isOn: Binding<Bool>) {
        self.id = id ?? title
        self.title = title
        self.description = description
        self.control = .toggle(isOn)
        self.chosenOptionWhenBuilt = nil
    }

    public init(
        _ title: String,
        id: String? = nil,
        description: String? = nil,
        options: [String],
        selection: Binding<Int>
    ) {
        self.id = id ?? title
        self.title = title
        self.description = description
        self.control = .select(options: options, selection: selection)
        self.chosenOptionWhenBuilt = selection.wrappedValue
    }

    public static func == (lhs: PinwheelTweak, rhs: PinwheelTweak) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.description == rhs.description
            && lhs.chosenOptionWhenBuilt == rhs.chosenOptionWhenBuilt
    }

    /// The names `-PinwheelPreviewTweak` can address. An option list offers its options rather than its
    /// own title, so a sweep captures every variant it holds instead of only the one that happens to be on.
    var previewVariantTitles: [String] {
        if case .select(let options, _) = control { return options }
        return [title]
    }

    /// Lands the deep-link preview on this variant: runs an action, forces a toggle on (never off), or
    /// selects the named option.
    func applyAsPreviewVariant(named name: String) {
        switch control {
        case .action(let action):
            action()
        case .toggle(let isOn):
            isOn.wrappedValue = true
        case .select(let options, let selection):
            guard let index = options.firstIndex(of: name) else { return }
            selection.wrappedValue = index
        }
    }
}

struct PinwheelTweaksPreferenceKey: PreferenceKey {
    static var defaultValue: [PinwheelTweak] = []

    static func reduce(value: inout [PinwheelTweak], nextValue: () -> [PinwheelTweak]) {
        value.append(contentsOf: nextValue())
    }
}

public extension SwiftUI.View {
    func pinwheelTweaks(@PinwheelTweakBuilder _ tweaks: @escaping () -> [PinwheelTweak]) -> some SwiftUI.View {
        preference(key: PinwheelTweaksPreferenceKey.self, value: tweaks())
    }

    func pinwheelTweaks(_ tweaks: [PinwheelTweak]) -> some SwiftUI.View {
        preference(key: PinwheelTweaksPreferenceKey.self, value: tweaks)
    }

    func pinwheelTweak(_ tweak: PinwheelTweak) -> some SwiftUI.View {
        preference(key: PinwheelTweaksPreferenceKey.self, value: [tweak])
    }
}
