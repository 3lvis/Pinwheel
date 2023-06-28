import UIKit

public extension UIFont {
    class var headline: UIFont {
        Config.fontProvider.headline
    }

    class var headlineSemibold: UIFont {
        Config.fontProvider.headlineSemibold
    }

    class var headlineBold: UIFont {
        Config.fontProvider.headlineBold
    }

    class var body: UIFont {
        Config.fontProvider.body
    }

    class var subheadline: UIFont {
        Config.fontProvider.subheadline
    }

    class var subheadlineBold: UIFont {
        Config.fontProvider.subheadlineBold
    }

    class var caption: UIFont {
        Config.fontProvider.caption
    }

    func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }
}
