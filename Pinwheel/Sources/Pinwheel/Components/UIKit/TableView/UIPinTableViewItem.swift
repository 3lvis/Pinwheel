import UIKit

public protocol UIPinTableViewItem {
    var title: String { get }
    var subtitle: String? { get }
    var isEnabled: Bool { get }
    var icon: UIImage? { get }
}

public extension UIPinTableViewItem {
    var icon: UIImage? { nil }
}
