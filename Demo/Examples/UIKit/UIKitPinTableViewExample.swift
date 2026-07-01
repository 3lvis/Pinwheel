import UIKit
import Pinwheel

class UIKitPinTableViewExample: UIKitPinView, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.tableView.state = .loading(title: DemoStateFixture.loadingTitle, subtitle: DemoStateFixture.loadingSubtitle)
            },
            TextTweak(title: "Loaded") {
                self.tableView.state = .loaded([UIKitPinTextTableViewItem(title: "Only value")])
            },
            TextTweak(title: "Empty") {
                self.tableView.state = .empty(title: DemoStateFixture.emptyTitle, subtitle: DemoStateFixture.emptySubtitle)
            },
            TextTweak(title: "Failed") {
                self.tableView.state = .failed(title: DemoStateFixture.failedTitle, subtitle: DemoStateFixture.failedSubtitle, actionTitle: DemoStateFixture.retryActionTitle)
            }
        ]
    }()

    lazy var tableView: UIKitPinTableView = {
        let view = UIKitPinTableView(items: items, usingShadowWhenScrolling: true)
        view.delegate = self
        return view
    }()

    lazy var items: [UIKitPinTableViewItem] = {
        let onlyTitle = UIKitPinTextTableViewItem(title: "Only title")

        let titleAndSubtitle = UIKitPinTextTableViewItem(title: "Title and subtitle", subtitle: "subtitle")

        let titleSubtitleAndDetail = UIKitPinTextTableViewItem(title: "Title, subtitle and detail", subtitle: "subtitle")
        titleSubtitleAndDetail.detailText = "Detail text"

        let titleAndDetail = UIKitPinTextTableViewItem(title: "Title and detail")
        titleAndDetail.detailText = "Detail text"

        let hasChevron = UIKitPinTextTableViewItem(title: "Has chevron")
        hasChevron.hasChevron = true

        let disabled = UIKitPinTextTableViewItem(title: "Is disabled")
        disabled.isEnabled = false

        let off = UIKitPinBoolTableViewItem(title: "Off")
        let on = UIKitPinBoolTableViewItem(title: "On")
        on.isOn = true

        let variants: [UIKitPinTableViewItem] = [
            onlyTitle,
            titleAndSubtitle,
            titleSubtitleAndDetail,
            titleAndDetail,
            disabled,
            hasChevron,
            off,
            on
        ]
        // Filler rows make the list overflow the sheet; the scroll-edge shadow
        // only shows once content scrolls.
        let filler = (1...12).map { UIKitPinTextTableViewItem(title: "Row \($0)") }
        return variants + filler
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension UIKitPinTableViewExample: UIKitPinTableViewDelegate {
    func tableView(_ tableView: Pinwheel.UIKitPinTableView, didSwitchItem boolTableViewItem: Pinwheel.UIKitPinBoolTableViewItem, atIndex index: Int) {
        let title = "Changed \(boolTableViewItem.title) to \(boolTableViewItem.isOn ? "on" : "off")"
        print(title)
    }
    
    func tableView(_ tableView: UIKitPinTableView, didSelectItemAtIndex index: Int) {
        let title = "Selected \((items[index] as? UIKitPinTextTableViewItem)?.title ?? "")"
        print(title)
    }

    func tableViewDidSelectFailedStateAction(_ tableView: UIKitPinTableView) {
        print("tapped!")
    }
}
