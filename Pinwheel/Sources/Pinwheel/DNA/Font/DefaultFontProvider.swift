import UIKit

public struct DefaultFontProvider: FontProvider {
    public var title: UIFont {
        let font = UIFont.systemFont(ofSize: 23, weight: .medium)
        return font.scaledFont(forTextStyle: .headline)
    }

    public var subtitle: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return font.scaledFont(forTextStyle: .subheadline)
    }

    public var body: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return font.scaledFont(forTextStyle: .body)
    }

    public var bodySemibold: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return font.scaledFont(forTextStyle: .body)
    }

    public var footnote: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return font.scaledFont(forTextStyle: .footnote)
    }

    public var caption: UIFont {
        let font = UIFont.systemFont(ofSize: 11, weight: .medium)
        return font.scaledFont(forTextStyle: .caption1)
    }

    public func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
