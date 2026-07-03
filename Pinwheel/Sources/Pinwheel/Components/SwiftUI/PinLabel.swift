import SwiftUI

/// SwiftUI's built-in `.body` / `.title` are Apple's system text styles that share
/// names with the design system but silently bypass it; `PinLabel` resolves the
/// provider-backed font, and taking a `PinTextStyle` (not a raw `Font`) makes the
/// system-font path unrepresentable.
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

        var tokenName: String? {
            switch self {
            case .primary: return "primaryText"
            case .secondary: return "secondaryText"
            case .tertiary: return "tertiaryText"
            case .action: return "actionText"
            case .critical: return "criticalText"
            case .custom: return nil
            }
        }
    }

    private let text: String
    private var typography: PinTextStyle = .body
    private var color: TextColor = .primary

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
            .font(typography.font)
            .foregroundStyle(color.color)
            .pinCaptured(name: "Label", text: text, textColorTokenName: color.tokenName, textStyle: typography)
    }
}
