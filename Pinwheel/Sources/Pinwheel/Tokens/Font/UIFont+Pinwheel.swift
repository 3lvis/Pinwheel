import UIKit

public extension UIFont {
    class var title: UIFont {
        Config.fontProvider.title
    }

    class var titleSemibold: UIFont {
        Config.fontProvider.titleSemibold
    }

    class var subtitle: UIFont {
        Config.fontProvider.subtitle
    }

    class var subtitleSemibold: UIFont {
        Config.fontProvider.subtitleSemibold
    }

    class var body: UIFont {
        Config.fontProvider.body
    }

    class var bodySemibold: UIFont {
        Config.fontProvider.bodySemibold
    }

    class var footnote: UIFont {
        Config.fontProvider.footnote
    }

    class var footnoteSemibold: UIFont {
        Config.fontProvider.footnoteSemibold
    }

    class var caption: UIFont {
        Config.fontProvider.caption
    }

    class var captionSemibold: UIFont {
        Config.fontProvider.captionSemibold
    }

    func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }
}
