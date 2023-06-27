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
        let defaultColor: UIColor = .init(hex: "#393F44")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: .white)
        } else {
            return defaultColor
        }
    }

    var secondaryText: UIColor {
        let defaultColor: UIColor = .init(hex: "#98A0A8")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: .init(hex: "#8D9AA5"))
        } else {
            return defaultColor
        }
    }

    var tertiaryText: UIColor {
        .init(hex: "#E0E7EA")
    }

    var primaryAction: UIColor {
        let defaultColor: UIColor = .init(hex: "#00B1FF")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: .init(hex: "#008BFF"))
        } else {
            return defaultColor
        }
    }

    var criticalAction: UIColor {
        .init(hex: "#FE4749")
    }

    var primaryBackground: UIColor {
        let defaultColor: UIColor = .white
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: .init(hex: "#1C2024"))
        } else {
            return defaultColor
        }
    }

    var secondaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "#F6FAFB")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: .init(hex: "#283036"))
        } else {
            return defaultColor
        }
    }

    var tertiaryBackground: UIColor {
        let defaultColor: UIColor = .init(hex: "#C3CCD9")
        let darkColor: UIColor = .init(hex: "#47535E")
        if #available(iOS 13.0, *) {
            return .dynamicColor(defaultColor: defaultColor, darkModeColor: darkColor)
        } else {
            return defaultColor
        }
    }

    var criticalBackground: UIColor {
        .init(hex: "#FBE7E6")
    }
}
