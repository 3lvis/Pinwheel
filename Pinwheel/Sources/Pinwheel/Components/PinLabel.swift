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
/// PinLabel("subtitle").style(.caption).color(PinwheelTheme.Colors.secondaryText)
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

    private let text: String
    private var style: Style = .body
    private var color: SwiftUI.Color = PinwheelTheme.Colors.primaryText

    public init(_ text: String) {
        self.text = text
    }

    /// Sets the typography style (default `.body`).
    public func style(_ style: Style) -> PinLabel {
        var copy = self
        copy.style = style
        return copy
    }

    /// Sets the text color (default `PinwheelTheme.Colors.primaryText`).
    public func color(_ color: SwiftUI.Color) -> PinLabel {
        var copy = self
        copy.color = color
        return copy
    }

    public var body: some SwiftUI.View {
        Text(text)
            .font(style.font)
            .foregroundStyle(color)
    }
}
