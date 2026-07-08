import UIKit

public protocol UIKitPinTableViewItem {
    var title: String { get }
    var subtitle: String? { get }
    var isEnabled: Bool { get }
    var icon: UIImage? { get }
}

public extension UIKitPinTableViewItem {
    var icon: UIImage? { nil }
}
