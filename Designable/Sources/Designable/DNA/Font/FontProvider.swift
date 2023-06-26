import UIKit

public protocol FontProvider {
    var body: UIFont { get }
    var bodyStrong: UIFont { get }

    var caption: UIFont { get }
    var captionStrong: UIFont { get }

    var detail: UIFont { get }
    var detailStrong: UIFont { get }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}

// MARK: - Default fonts

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

// MARK: - Private extensions

private extension UIFont {
    static func registerFont(with filenameString: String) {
        if let bundleURL = Bundle.designable.url(forResource: "Designable", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                registerFontFor(bundle: bundle, forResource: filenameString)
                return
            }
        }

        if let bundleIdentifier = Bundle.designable.bundleIdentifier {
            if let bundle = Bundle(identifier: bundleIdentifier) {
                registerFontFor(bundle: bundle, forResource: filenameString)
            }
        }
    }

    private static func registerFontFor(bundle: Bundle, forResource: String) {
        guard let pathForResourceString = bundle.path(forResource: forResource, ofType: "ttf") else {
            print("UIFont+: Failed to register font - path for resource not found.")
            return
        }

        guard let fontData = NSData(contentsOfFile: pathForResourceString) else {
            print("UIFont+: Failed to register font - font data could not be loaded.")
            return
        }

        guard let dataProvider = CGDataProvider(data: fontData) else {
            print("UIFont+: Failed to register font - data provider could not be loaded.")
            return
        }

        guard let fontRef = CGFont(dataProvider) else {
            print("UIFont+: Failed to register font - font could not be loaded.")
            return
        }

        var errorRef: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(fontRef, &errorRef)
    }
}
