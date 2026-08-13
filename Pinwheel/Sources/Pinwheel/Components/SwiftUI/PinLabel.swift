import SwiftUI

public struct PinLabel: SwiftUI.View {
    public enum TextColor {
        case primary
        case secondary
        case tertiary
        case action
        case critical
        case custom(SwiftUI.Color)

        var color: SwiftUI.Color {
            switch self {
            case .primary: return .primaryText
            case .secondary: return .secondaryText
            case .tertiary: return .tertiaryText
            case .action: return .actionText
            case .critical: return .criticalText
            case .custom(let color): return color
            }
        }
    }

    private let text: String
    private var typography: PinTextStyle = .body
    private var color: TextColor = .primary

    @Environment(\.pinwheelTheme) private var theme

    public init(_ text: String) {
        self.text = text
    }

    public func font(_ font: PinTextStyle) -> PinLabel {
        var copy = self
        copy.typography = font
        return copy
    }

    public func color(_ color: TextColor) -> PinLabel {
        var copy = self
        copy.color = color
        return copy
    }

    public var body: some SwiftUI.View {
        Text(text)
            .font(typography.font(in: theme))
            .foregroundStyle(color.color)
    }
}
