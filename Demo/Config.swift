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

public extension UIFont {
    class var titleSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 23, weight: .semibold)
        return font.scaledFont(forTextStyle: .headline)
    }

    class var subtitleSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 20, weight: .semibold)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    class var bodySemibold: UIFont {
        let font = UIFont.rounded(ofSize: 17, weight: .semibold)
        return font.scaledFont(forTextStyle: .body)
    }

    class var footnoteSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 13, weight: .semibold)
        return font.scaledFont(forTextStyle: .footnote)
    }

    class var captionSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 11, weight: .semibold)
        return font.scaledFont(forTextStyle: .caption1)
    }
}

struct DemoColorProvider: ColorProvider {
    var primaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "021622")
        let darkColor: UIColor = .init(hex: "FFFFFF")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var secondaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "98A0A8")
        let darkColor: UIColor = .init(hex: "8D9AA5")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var tertiaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "E0E7EA")
        let darkColor: UIColor = .init(hex: "404850")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }
    
    var actionText: UIColor {
        return .init(hex: "00B1FF")
    }

    var criticalText: UIColor {
        let defaultColor: UIColor = .init(hex: "FE4749")
        let darkColor: UIColor = .init(hex: "C90002")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var primaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FFFFFF")
        let darkColor: UIColor = .init(hex: "1C2024")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var secondaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "F3F8F9")
        let darkColor: UIColor = .init(hex: "2A3036")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var actionBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "DEF5FF")
        let darkColor: UIColor = .init(hex: "003349")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var criticalBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FBE7E6")
        let darkColor: UIColor = .init(hex: "3D2525")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }
}
