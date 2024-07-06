import UIKit

public extension UIFont {
    class var title: UIFont {
        Config.fontProvider.title
    }

    class var subtitle: UIFont {
        Config.fontProvider.subtitle
    }

    class var body: UIFont {
        Config.fontProvider.body
    }

    class var footnote: UIFont {
        Config.fontProvider.footnote
    }

    class var caption: UIFont {
        Config.fontProvider.caption
    }

    func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }
}
