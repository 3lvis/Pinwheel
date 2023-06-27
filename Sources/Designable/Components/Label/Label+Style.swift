import UIKit

public extension Label {
    enum Style {
        case bodyStrong
        case detailStrong
        case body
        case captionStrong
        case caption
        case detail

        public var font: UIFont {
            switch self {
            case .bodyStrong: return UIFont.bodyStrong
            case .detailStrong: return UIFont.detailStrong
            case .body: return UIFont.body
            case .captionStrong: return UIFont.captionStrong
            case .caption: return UIFont.caption
            case .detail: return UIFont.detail
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
