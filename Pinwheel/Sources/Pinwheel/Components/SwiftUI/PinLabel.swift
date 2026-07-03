import SwiftUI
import PinwheelMacros

/// SwiftUI's built-in `.body` / `.title` are Apple's system text styles that share
/// names with the design system but silently bypass it; `PinLabel` resolves the
/// provider-backed font, and taking a `PinTextStyle` (not a raw `Font`) makes the
/// system-font path unrepresentable.
@Pinnable
public struct PinLabel: SwiftUI.View {
    public enum TextColor: PinTextColorToken {
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

        public var captureTextColorToken: String? {
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

    @PinText private let text: String
    @PinTypography private var typography: PinTextStyle = .body
    @PinColor private var color: TextColor = .primary

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
            .pinCaptured(pinnedStyle)
    }
}
