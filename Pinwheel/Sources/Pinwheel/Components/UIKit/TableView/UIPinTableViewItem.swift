import UIKit

public protocol UIPinTableViewItem {
    var title: String { get }
    var subtitle: String? { get }
    var isEnabled: Bool { get }
    var icon: UIImage? { get }
}

extension UIPinTableViewItem {
    public var icon: UIImage? { nil }
}
