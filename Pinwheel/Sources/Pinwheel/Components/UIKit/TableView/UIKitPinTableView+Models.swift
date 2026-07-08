import UIKit

open class UIKitPinTextTableViewItem: UIKitPinTableViewItem {
    open var title: String
    open var subtitle: String?
    open var isEnabled: Bool = true
    open var detailText: String?
    open var hasChevron: Bool
    open var icon: UIImage?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.hasChevron = false
    }
}

open class UIKitPinBoolTableViewItem: UIKitPinTableViewItem {
    open var title: String
    open var subtitle: String?
    open var isEnabled: Bool = true
    open var isOn: Bool = false
    open var icon: UIImage?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}
