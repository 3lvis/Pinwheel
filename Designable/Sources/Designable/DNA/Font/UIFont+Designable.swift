import UIKit

public extension UIFont {
    /// ## Usage:
    /// - Regular text below titles is called body text
    class var body: UIFont {
        Config.fontProvider.body
    }

    /// ## Usage:
    /// - This have the same size as the body text, but is always bolded to differenciate them.
    class var bodyStrong: UIFont {
        Config.fontProvider.bodyStrong
    }

    /// ## Usage:
    /// - Used for short amount of text if neither the Body or Detail is appropriate.
    /// - This is slightly smaller than body text.
    class var caption: UIFont {
        Config.fontProvider.caption
    }

    /// ## Usage:
    /// - Used for short amount of text if neither the Body or Detail is appropriate.
    /// - Bold version of Caption
    /// - This is slightly smaller than body text.
    class var captionStrong: UIFont {
        Config.fontProvider.captionStrong
    }


    /// ## Usage:
    /// - Less important information can be shown as detail text, not for long sentences.
    /// - This is slightly smaller than body text.
    class var detail: UIFont {
        Config.fontProvider.detail
    }

    /// ## Usage:
    /// - Used for small, bold headlines.
    class var detailStrong: UIFont {
        Config.fontProvider.detailStrong
    }

    func scaledFont(forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        return fontMetrics.scaledFont(for: self)
    }
}
