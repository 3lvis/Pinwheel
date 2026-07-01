import UIKit

extension UITraitCollection {
    /// For use where a `traitCollection` is unavailable, e.g. outside views or view controllers.
    public static var isHorizontalSizeClassRegular: Bool {
        if #available(iOS 13.0, *) {
            return current.horizontalSizeClass == .regular
        } else {
            return true
        }
    }
}
