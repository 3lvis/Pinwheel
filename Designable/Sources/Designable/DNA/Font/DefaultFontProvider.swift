import UIKit

public struct DefaultFontProvider: FontProvider {
    public var headline: UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }

    public var headlineSemibold: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        if let boldDescriptor = descriptor.withSymbolicTraits(.traitBold) {
          return UIFont(descriptor: boldDescriptor, size: 0)
        } else {
            let font = UIFont.systemFont(ofSize: 16, weight: .bold)
            return font.scaledFont(forTextStyle: .headline)
        }
    }

    public var headlineBold: UIFont {
        let font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return font.scaledFont(forTextStyle: .headline)
    }

    public var body: UIFont {
        return UIFont.preferredFont(forTextStyle: .body)
    }

    public var subheadline: UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    public var subheadlineBold: UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }

    public var caption: UIFont {
        return UIFont.preferredFont(forTextStyle: .caption1)
    }

    public func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
