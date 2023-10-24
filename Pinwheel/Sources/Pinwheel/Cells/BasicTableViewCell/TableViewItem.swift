import Foundation

public protocol TableViewItem {
    var title: String { get }
    var subtitle: String? { get }
    var isEnabled: Bool { get }
}
