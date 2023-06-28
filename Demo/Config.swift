import Designable

struct DemoFontProvider: FontProvider {
    var headline: UIFont {
        let font = UIFont.rounded(ofSize: 22, weight: .medium)
        return font.scaledFont(forTextStyle: .headline)
    }

    var headlineSemibold: UIFont {
        let font = UIFont.rounded(ofSize: 22, weight: .semibold)
        return font.scaledFont(forTextStyle: .headline)
    }

    var headlineBold: UIFont {
        let font = UIFont.rounded(ofSize: 22, weight: .bold)
        return font.scaledFont(forTextStyle: .headline)
    }

    var body: UIFont {
        let font = UIFont.rounded(ofSize: 20, weight: .medium)
        return font.scaledFont(forTextStyle: .body)
    }

    var subheadline: UIFont {
        let font = UIFont.rounded(ofSize: 18, weight: .medium)
        return font.scaledFont(forTextStyle: .subheadline)
    }
    var subheadlineBold: UIFont {
        let font = UIFont.rounded(ofSize: 18, weight: .bold)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    var caption: UIFont {
        let font = UIFont.rounded(ofSize: 14, weight: .medium)
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

    var primaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FFFFFF")
        let darkColor: UIColor = .init(hex: "98A0A8")
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

    var primaryAction: UIColor {
        return .init(hex: "00B1FF")
    }

    var activeBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "DEF5FF")
        let darkColor: UIColor = .init(hex: "003349")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var criticalAction: UIColor {
        .init(hex: "FE4749")
    }

    var criticalBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "FBE7E6")
        let darkColor: UIColor = .init(hex: "2F0C0A")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }
}
