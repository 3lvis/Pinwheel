import UIKit
import Pinwheel

class PinTableView: UIKitPinView, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.tableView.state = .loading(title: "Loading...", subtitle: "Please wait while we fetch your details.")
            },
            TextTweak(title: "Loaded") {
                self.tableView.state = .loaded([UIKitPinTextTableViewItem(title: "Only value")])
            },
            TextTweak(title: "Empty") {
                self.tableView.state = .empty(title: "Ready to Move?", subtitle: "Kick things off with your first booking.")
            },
            TextTweak(title: "Failed") {
                self.tableView.state = .failed(title: "Oops!", subtitle: "We couldn't load your bookings.", actionTitle: "Retry")
            }
        ]
    }()

    lazy var tableView: UIKitPinTableView = {
        let view = UIKitPinTableView(items: items)
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

        return [
            onlyTitle,
            titleAndSubtitle,
            titleSubtitleAndDetail,
            titleAndDetail,
            disabled,
            hasChevron,
            off,
            on
        ]
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension PinTableView: UIKitPinTableViewDelegate {
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
