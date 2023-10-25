import UIKit

open class TextTableViewItem: TableViewItem {
    open var title: String
    open var subtitle: String?
    open var isEnabled: Bool = true
    open var detailText: String?
    open var hasChevron: Bool

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = false
    }
}

open class BoolTableViewItem: TableViewItem {
    open var title: String
    open var subtitle: String?
    open var isEnabled: Bool = true
    open var isOn: Bool = false

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}
