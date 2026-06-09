import Foundation

public protocol UIKitPinTableViewItem {
    var title: String { get }
    var subtitle: String? { get }
    var isEnabled: Bool { get }
}
