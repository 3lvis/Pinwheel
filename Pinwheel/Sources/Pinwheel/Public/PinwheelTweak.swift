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
    }

    public let id: String
    public let title: String
    public let description: String?
    let control: Control

    public init(_ title: String, id: String? = nil, description: String? = nil, action: @escaping () -> Void) {
        self.id = id ?? title
        self.title = title
        self.description = description
        self.control = .action(action)
    }

    public init(_ title: String, id: String? = nil, description: String? = nil, isOn: Binding<Bool>) {
        self.id = id ?? title
        self.title = title
        self.description = description
        self.control = .toggle(isOn)
    }

    public static func == (lhs: PinwheelTweak, rhs: PinwheelTweak) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.description == rhs.description
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
