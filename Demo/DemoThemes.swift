import UIKit
import Pinwheel

struct DemoFontProvider: FontProvider {
    var title: UIFont {
        let font = UIFont.rounded(ofSize: 23, weight: .medium)
        return font.scaledFont(forTextStyle: .headline)
    }

    var subtitle: UIFont {
        let font = UIFont.rounded(ofSize: 20, weight: .medium)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    var subtitleSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 20, weight: .semibold)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    var body: UIFont {
        let font = UIFont.rounded(ofSize: 17, weight: .medium)
        return font.scaledFont(forTextStyle: .body)
    }

    var footnote: UIFont {
        let font = UIFont.rounded(ofSize: 13, weight: .medium)
        return font.scaledFont(forTextStyle: .footnote)
    }

    var caption: UIFont {
        let font = UIFont.rounded(ofSize: 11, weight: .medium)
        return font.scaledFont(forTextStyle: .caption1)
    }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.rounded(ofSize: size, weight: weight)
    }
}

struct DemoColorProvider: ColorProvider {
    var primaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "021622")
        let darkColor: UIColor = .init(hex: "FFFFFF")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var secondaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "98A0A8")
        let darkColor: UIColor = .init(hex: "8D9AA5")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var tertiaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "E0E7EA")
        let darkColor: UIColor = .init(hex: "404850")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }
    
    var actionText: UIColor {
        return .init(hex: "00B1FF")
    }

    var criticalText: UIColor {
        let defaultColor: UIColor = .init(hex: "FE4749")
        let darkColor: UIColor = .init(hex: "C90002")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var primaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FFFFFF")
        let darkColor: UIColor = .init(hex: "1C2024")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var secondaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "F3F8F9")
        let darkColor: UIColor = .init(hex: "2A3036")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var actionBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "DEF5FF")
        let darkColor: UIColor = .init(hex: "003349")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }

    var criticalBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FBE7E6")
        let darkColor: UIColor = .init(hex: "3D2525")
        return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
    }
}

struct EmberFontProvider: FontProvider {
    var title: UIFont { serif(23, .bold).scaledFont(forTextStyle: .headline) }
    var subtitle: UIFont { serif(20, .semibold).scaledFont(forTextStyle: .subheadline) }
    var subtitleSemibold: UIFont { serif(20, .bold).scaledFont(forTextStyle: .subheadline) }
    var body: UIFont { serif(17, .regular).scaledFont(forTextStyle: .body) }
    var footnote: UIFont { serif(13, .regular).scaledFont(forTextStyle: .footnote) }
    var caption: UIFont { serif(11, .regular).scaledFont(forTextStyle: .caption1) }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        serif(size, weight)
    }

    private func serif(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

struct EmberColorProvider: ColorProvider {
    var primaryText: UIColor { dynamic("2B1707", "FFF3E6") }
    var secondaryText: UIColor { dynamic("9A7B5E", "C4A98C") }
    var tertiaryText: UIColor { dynamic("E8D9C7", "5A4633") }
    var actionText: UIColor { dynamic("D2600A", "FF9B3D") }
    var criticalText: UIColor { dynamic("B3261E", "F2B8B5") }

    var primaryBackground: UIColor { dynamic("FFFBF5", "241A10") }
    var secondaryBackground: UIColor { dynamic("F7ECDF", "352718") }
    var actionBackground: UIColor { dynamic("FFE3C4", "51300C") }
    var criticalBackground: UIColor { dynamic("F9DEDC", "3D2525") }

    private func dynamic(_ light: String, _ dark: String) -> UIColor {
        .dynamicColor(defaultColor: .init(hex: light), darkModeColor: .init(hex: dark))
    }
}

enum DemoThemes {
    static let all: [PinwheelTheme] = [.marine, .ember]
}

extension PinwheelTheme {
    static let marine = PinwheelTheme(
        name: "Marine",
        colors: DemoColorProvider(),
        fonts: DemoFontProvider()
    )

    static let ember = PinwheelTheme(
        name: "Ember",
        colors: EmberColorProvider(),
        fonts: EmberFontProvider(),
        buttonShape: .capsule
    )
}
