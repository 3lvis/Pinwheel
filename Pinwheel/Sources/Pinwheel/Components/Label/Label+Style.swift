import UIKit

public extension Label {
    enum Style {
        case headline
        case headlineSemibold
        case headlineBold

        case body

        case subheadline
        case subheadlineSemibold
        case subheadlineBold

        case caption

        public var font: UIFont {
            switch self {
            case .headline: return UIFont.headline
            case .headlineSemibold: return UIFont.headlineSemibold
            case .headlineBold: return UIFont.headlineBold
            case .body: return UIFont.body
            case .subheadline: return UIFont.subheadline
            case .subheadlineSemibold: return UIFont.subheadlineSemibold
            case .subheadlineBold: return UIFont.subheadlineBold
            case .caption: return UIFont.caption
            }
        }

        var padding: UIEdgeInsets {
            return UIEdgeInsets(top: lineSpacing, left: 0, bottom: 0, right: 0)
        }

        var lineSpacing: CGFloat {
            switch self {
            default: return 0
            }
        }
    }
}
