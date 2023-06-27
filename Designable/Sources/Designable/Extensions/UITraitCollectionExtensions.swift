import UIKit

extension UITraitCollection {
    /// This method is intented to be used where `traitCollection` is not available, for example
    /// outside of views or view controllers. Given the idea is to identify if the horizontal size class is regular.
    public static var isHorizontalSizeClassRegular: Bool {
        if #available(iOS 13.0, *) {
            return current.horizontalSizeClass == .regular
        } else {
            return true
        }
    }
}
