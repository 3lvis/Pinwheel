import SwiftUI

/// SwiftUI-native themed text — the counterpart to the UIKit `UIKitPinLabel`.
///
/// Prefer this over `Text(...).font(.body)`: SwiftUI's built-in `.body` / `.title`
/// are *Apple's* system text styles that share names with the design system but
/// silently bypass it. `PinLabel("Title", style: .title)` always resolves the
/// provider-backed `PinwheelTheme.Typography` font, with `primaryText` color by
/// default. The `Style` enum (not `Font`) is deliberate — it makes the wrong,
/// system-font path unrepresentable at the call site.
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
    private let style: Style
    private let color: SwiftUI.Color

    public init(
        _ text: String,
        style: Style = .body,
        color: SwiftUI.Color = PinwheelTheme.Colors.primaryText
    ) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some SwiftUI.View {
        Text(text)
            .font(style.font)
            .foregroundStyle(color)
    }
}
