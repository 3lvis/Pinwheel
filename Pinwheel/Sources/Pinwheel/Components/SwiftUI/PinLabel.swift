import SwiftUI

/// SwiftUI-native themed text — the counterpart to the UIKit `UIKitPinLabel`.
///
/// Prefer this over `Text(...).font(.body)`: SwiftUI's built-in `.body` / `.title`
/// are *Apple's* system text styles that share names with the design system but
/// silently bypass it. `PinLabel` always resolves the provider-backed
/// `PinwheelTheme.Typography` font. Taking a `PinTextStyle` (not a raw `Font`) is
/// deliberate — it makes the wrong, system-font path unrepresentable.
///
/// Styling reads like SwiftUI — `.font(_:)` matches `PinButton.font(_:)`; the font
/// defaults to `.body` and color to `.primary`, so the common case is just the text:
///
/// ```swift
/// PinLabel("Has chevron")                                 // body, primary
/// PinLabel("Title").font(.title)
/// PinLabel("subtitle").font(.caption).color(.secondary)   // .custom(_) for arbitrary colors
/// ```
///
/// `PinLabel` is a pure SwiftUI value (no `UIHostingController`): Label is the one
/// component where SwiftUI and UIKit each have an independent trivial implementation
/// fed by the same `Config` provider tokens, so neither needs to host the other.
public struct PinLabel: SwiftUI.View {
    /// A themed text color role. Use the semantic cases to stay on the design
    /// system; `.custom(_)` is the escape hatch for an arbitrary color (named to
    /// match `PinButton.Style.custom`).
    public enum TextColor {
        case primary
        case secondary
        case tertiary
        case action
        case critical
        case custom(SwiftUI.Color)

        var color: SwiftUI.Color {
            switch self {
            case .primary: return PinwheelTheme.Colors.primaryText
            case .secondary: return PinwheelTheme.Colors.secondaryText
            case .tertiary: return PinwheelTheme.Colors.tertiaryText
            case .action: return PinwheelTheme.Colors.actionText
            case .critical: return PinwheelTheme.Colors.criticalText
            case .custom(let color): return color
            }
        }
    }

    private let text: String
    private var typography: PinTextStyle = .body
    private var color: TextColor = .primary

    public init(_ text: String) {
        self.text = text
    }

    /// Sets the typography (default `.body`).
    public func font(_ font: PinTextStyle) -> PinLabel {
        var copy = self
        copy.typography = font
        return copy
    }

    /// Sets the text color role (default `.primary`). Use `.custom(_)` for an
    /// arbitrary color.
    public func color(_ color: TextColor) -> PinLabel {
        var copy = self
        copy.color = color
        return copy
    }

    public var body: some SwiftUI.View {
        Text(text)
            .font(typography.font)
            .foregroundStyle(color.color)
    }
}
