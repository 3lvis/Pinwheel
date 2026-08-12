import SwiftUI
import UIKit

public enum PinTextStyle {
    case title
    case titleSemibold
    case subtitle
    case subtitleSemibold
    case body
    case bodySemibold
    case footnote
    case footnoteSemibold
    case caption
    case captionSemibold

    public func font(in theme: PinwheelTheme) -> SwiftUI.Font {
        SwiftUI.Font(uiFont(in: theme))
    }

    func uiFont(in theme: PinwheelTheme) -> UIFont {
        let fonts = theme.fonts
        switch self {
        case .title: return fonts.title
        case .titleSemibold: return fonts.titleSemibold
        case .subtitle: return fonts.subtitle
        case .subtitleSemibold: return fonts.subtitleSemibold
        case .body: return fonts.body
        case .bodySemibold: return fonts.bodySemibold
        case .footnote: return fonts.footnote
        case .footnoteSemibold: return fonts.footnoteSemibold
        case .caption: return fonts.caption
        case .captionSemibold: return fonts.captionSemibold
        }
    }
}

public nonisolated struct PinwheelTheme: Sendable {
    public let name: String
    public let colors: ColorProvider
    public let fonts: FontProvider
    public let buttonShape: PinButtonShape

    public init(name: String, colors: ColorProvider, fonts: FontProvider) {
        self.init(name: name, colors: colors, fonts: fonts, buttonShape: .rounded)
    }

    public init(name: String, colors: ColorProvider, fonts: FontProvider, buttonShape: PinButtonShape) {
        self.name = name
        self.colors = colors
        self.fonts = fonts
        self.buttonShape = buttonShape
    }
}

nonisolated extension PinwheelTheme: Identifiable {
    public var id: String { name }
}

nonisolated extension PinwheelTheme: Equatable {
    public static func == (lhs: PinwheelTheme, rhs: PinwheelTheme) -> Bool {
        lhs.name == rhs.name
    }
}

public nonisolated extension PinwheelTheme {
    static let standard = PinwheelTheme(
        name: "Standard",
        colors: DefaultColorProvider(),
        fonts: DefaultFontProvider()
    )
}

/// `.red`-style shorthand for the themed colors. The leading-dot form needs a
/// `ShapeStyle`/`Color` context to resolve; at `.listRowBackground(_:)` (a generic
/// `View` parameter) spell the type: `Color.primaryBackground`.
public extension ShapeStyle where Self == Color {
    static var primaryText: Color { Color(uiColor: .primaryText) }
    static var secondaryText: Color { Color(uiColor: .secondaryText) }
    static var tertiaryText: Color { Color(uiColor: .tertiaryText) }
    static var actionText: Color { Color(uiColor: .actionText) }
    static var criticalText: Color { Color(uiColor: .criticalText) }

    static var primaryBackground: Color { Color(uiColor: .primaryBackground) }
    static var secondaryBackground: Color { Color(uiColor: .secondaryBackground) }
    static var actionBackground: Color { Color(uiColor: .actionBackground) }
    static var criticalBackground: Color { Color(uiColor: .criticalBackground) }
}
