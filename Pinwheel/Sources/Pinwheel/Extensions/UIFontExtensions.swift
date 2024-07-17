import UIKit

extension UIFont {
    public class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont

        if #available(iOS 13.0, *) {
            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: size)
            } else {
                font = systemFont
            }
        } else {
            font = systemFont
        }
        return font
    }

    public var weight: UIFont.Weight {
        let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        let weightValue = traits?[.weight] as? NSNumber
        return UIFont.Weight(rawValue: CGFloat(weightValue?.floatValue ?? Float(UIFont.Weight.regular.rawValue)))
    }
}

extension UIFont.Weight {
    public var symbolWeight: UIImage.SymbolWeight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        default:
            return .regular
        }
    }
}
