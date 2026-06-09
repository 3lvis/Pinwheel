import SwiftUI
import UIKit

/// The themed typography scale — the font token used by `PinLabel.font(_:)` and
/// `PinButton.font(_:)`. Parallels Apple's `Font.TextStyle`, but resolves the
/// provider-backed `PinwheelTheme.Typography` fonts instead of system styles.
public enum PinTextStyle {
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

/// The deliberate UIKit→SwiftUI token adaptor: every token resolves a
/// provider-backed `UIFont`/`UIColor` (via the `Config` providers) and wraps it
/// as a SwiftUI `Font`/`Color`, so both worlds stay on the same design tokens.
public enum PinwheelTheme {
    public enum Typography {
        public static var title: Font { Font(UIFont.title) }
        public static var subtitle: Font { Font(UIFont.subtitle) }
        public static var subtitleSemibold: Font { Font(UIFont.subtitleSemibold) }
        public static var body: Font { Font(UIFont.body) }
        public static var footnote: Font { Font(UIFont.footnote) }
        public static var caption: Font { Font(UIFont.caption) }
    }

    public enum Colors {
        public static var primaryText: Color { Color(uiColor: .primaryText) }
        public static var secondaryText: Color { Color(uiColor: .secondaryText) }
        public static var tertiaryText: Color { Color(uiColor: .tertiaryText) }
        public static var actionText: Color { Color(uiColor: .actionText) }
        public static var criticalText: Color { Color(uiColor: .criticalText) }

        public static var primaryBackground: Color { Color(uiColor: .primaryBackground) }
        public static var secondaryBackground: Color { Color(uiColor: .secondaryBackground) }
        public static var actionBackground: Color { Color(uiColor: .actionBackground) }
        public static var criticalBackground: Color { Color(uiColor: .criticalBackground) }
    }
}

/// SwiftUI-native shorthand for the themed colors, so any `ShapeStyle`/`Color`
/// context takes a token the way it takes `.red` — `.background(.primaryBackground)`,
/// `.foregroundStyle(.actionText)`, `.tint(.actionText)`. These forward to the
/// canonical `PinwheelTheme.Colors` tokens; the leading-dot form just removes the
/// `PinwheelTheme.Colors.` noise at call sites. (Doesn't reach `.listRowBackground`,
/// whose parameter is a generic `View`, not a `ShapeStyle` — those stay spelled out.)
public extension ShapeStyle where Self == Color {
    static var primaryText: Color { PinwheelTheme.Colors.primaryText }
    static var secondaryText: Color { PinwheelTheme.Colors.secondaryText }
    static var tertiaryText: Color { PinwheelTheme.Colors.tertiaryText }
    static var actionText: Color { PinwheelTheme.Colors.actionText }
    static var criticalText: Color { PinwheelTheme.Colors.criticalText }

    static var primaryBackground: Color { PinwheelTheme.Colors.primaryBackground }
    static var secondaryBackground: Color { PinwheelTheme.Colors.secondaryBackground }
    static var actionBackground: Color { PinwheelTheme.Colors.actionBackground }
    static var criticalBackground: Color { PinwheelTheme.Colors.criticalBackground }
}
