import UIKit

public struct DefaultFontProvider: FontProvider {
    /// OpenSans-Light with a size of 16 scaled for UIFontTextStyle.body
    ///
    /// ## Usage:
    /// - Regular text below titles is called body text and is weighted Medium.
    public var body: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }

    /// OpenSans-Medium with a size of 16 scaled for UIFontTextStyle.body
    ///
    /// ## Usage:
    /// - This have the same size as the body text, but is always bolded (Medium) to differenciate them.
    public var bodyStrong: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        if let boldDescriptor = descriptor.withSymbolicTraits(.traitBold) {
          return UIFont(descriptor: boldDescriptor, size: 0)
        } else {
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            return font.scaledFont(forTextStyle: .body)
        }
    }

    /// OpenSans-Light with a size of 14 scaled for UIFontTextStyle.subheadline
    ///
    /// ## Usage:
    /// - Less important information can be shown as detail text, not for long sentences.
    /// - This is slightly smaller than body text. Weighted Regular.
    /// - The color Stone is prefered in most cases with white background.
    /// - For colored background such as ribbons, the color should be Licorice.
    public var detail: UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    /// OpenSans-Bold with a size of 14 scaled for UIFontTextStyle.subheadline
    ///
    /// ## Usage:
    /// - Used for small, bold headlines.
    public var detailStrong: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        if let boldDescriptor = descriptor.withSymbolicTraits(.traitBold) {
          return UIFont(descriptor: boldDescriptor, size: 0)
        } else {
            let font = UIFont.systemFont(ofSize: 14, weight: .bold)
            return font.scaledFont(forTextStyle: .subheadline)
        }
    }

    /// OpenSans-Light with a size of 12 scaled for UIFontTextStyle.caption1
    ///
    /// ## Usage:
    /// - Used for short amount of text if neither the Body or Detail is appropriate.
    /// - This is slightly smaller than body text. Weighted Light.
    public var caption: UIFont {
        return UIFont.preferredFont(forTextStyle: .caption1)
    }

    /// OpenSans-Light with a size of 12 scaled for UIFontTextStyle.caption1
    ///
    /// ## Usage:
    /// - Used for short amount of text if neither the Body or Detail is appropriate.
    /// - Bold version of Caption
    /// - This is slightly smaller than body text. Weighted Medium.
    public var captionStrong: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1)
        if let boldDescriptor = descriptor.withSymbolicTraits(.traitBold) {
          return UIFont(descriptor: boldDescriptor, size: 0)
        } else {
            let font = UIFont.systemFont(ofSize: 12, weight: .medium)
            return font.scaledFont(forTextStyle: .caption1)
        }
    }

    public func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
