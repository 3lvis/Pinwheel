import UIKit

public struct DefaultFontProvider: FontProvider {
    public var headline: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .regular)
        return font.scaledFont(forTextStyle: .headline)
    }

    public var headlineSemibold: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        return font.scaledFont(forTextStyle: .headline)
    }

    public var headlineBold: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return font.scaledFont(forTextStyle: .headline)
    }

    public var body: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        return font.scaledFont(forTextStyle: .body)
    }

    public var subheadline: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    public var subheadlineBold: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .bold)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    public var caption: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return font.scaledFont(forTextStyle: .caption1)
    }

    public func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
