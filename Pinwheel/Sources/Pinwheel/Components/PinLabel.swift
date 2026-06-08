import SwiftUI

/// SwiftUI-native themed text — the counterpart to the UIKit `UIKitPinLabel`.
///
/// Prefer this over `Text(...).font(.body)`: SwiftUI's built-in `.body` / `.title`
/// are *Apple's* system text styles that share names with the design system but
/// silently bypass it. `PinLabel` always resolves the provider-backed
/// `PinwheelTheme.Typography` font. The `Style` enum (not `Font`) is deliberate —
/// it makes the wrong, system-font path unrepresentable at the call site.
///
/// Styling reads like SwiftUI; `style` defaults to `.body` and `color` to
/// `primaryText`, so the common case is just the text:
///
/// ```swift
/// PinLabel("Has chevron")                                // body, primaryText
/// PinLabel("Title").style(.title)                        // themed title
/// PinLabel("subtitle").style(.caption).color(.secondary)   // .raw(_) for arbitrary colors
/// ```
///
/// `PinLabel` is a pure SwiftUI value (no `UIHostingController`): Label is the one
/// component where SwiftUI and UIKit each have an independent trivial implementation
/// fed by the same `Config` provider tokens, so neither needs to host the other.
public struct PinLabel: SwiftUI.View {
    public enum Style {
        case title
        case subtitle
        case subtitleSemibold
        case body
        case footnote
        case caption

        var font: SwiftUI.Font {
            switch self {
            case .title: return PinwheelTheme.Typography.title
            case .subtitle: return PinwheelTheme.Typography.subtitle
            case .subtitleSemibold: return PinwheelTheme.Typography.subtitleSemibold
            case .body: return PinwheelTheme.Typography.body
            case .footnote: return PinwheelTheme.Typography.footnote
            case .caption: return PinwheelTheme.Typography.caption
            }
        }
    }

    /// A themed text color role. Use the semantic cases to stay on the design
    /// system; `.raw(_)` is the escape hatch for an arbitrary color.
    public enum TextColor {
        case primary
        case secondary
        case tertiary
        case action
        case critical
        case raw(SwiftUI.Color)

        var color: SwiftUI.Color {
            switch self {
            case .primary: return PinwheelTheme.Colors.primaryText
            case .secondary: return PinwheelTheme.Colors.secondaryText
            case .tertiary: return PinwheelTheme.Colors.tertiaryText
            case .action: return PinwheelTheme.Colors.actionText
            case .critical: return PinwheelTheme.Colors.criticalText
            case .raw(let color): return color
            }
        }
    }

    private let text: String
    private var style: Style = .body
    private var color: TextColor = .primary

    public init(_ text: String) {
        self.text = text
    }

    /// Sets the typography style (default `.body`).
    public func style(_ style: Style) -> PinLabel {
        var copy = self
        copy.style = style
        return copy
    }

    /// Sets the text color role (default `.primary`). Use `.raw(_)` for an
    /// arbitrary color.
    public func color(_ color: TextColor) -> PinLabel {
        var copy = self
        copy.color = color
        return copy
    }

    public var body: some SwiftUI.View {
        Text(text)
            .font(style.font)
            .foregroundStyle(color.color)
    }
}
