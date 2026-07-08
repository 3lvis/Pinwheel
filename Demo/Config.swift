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
