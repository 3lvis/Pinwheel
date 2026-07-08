import UIKit
import Pinwheel

class UIKitPinTableViewDemo: UIKitPinView, Tweakable {
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
        @MainActor func text(_ title: String, icon: String, subtitle: String? = nil, detail: String? = nil, chevron: Bool = false, enabled: Bool = true) -> UIKitPinTextTableViewItem {
            let item = UIKitPinTextTableViewItem(title: title, subtitle: subtitle)
            item.icon = UIImage(systemName: icon)
            item.detailText = detail
            item.hasChevron = chevron
            item.isEnabled = enabled
            return item
        }
        @MainActor func toggle(_ title: String, icon: String, isOn: Bool) -> UIKitPinBoolTableViewItem {
            let item = UIKitPinBoolTableViewItem(title: title)
            item.icon = UIImage(systemName: icon)
            item.isOn = isOn
            return item
        }
        return [
            text("Account", icon: "person.crop.circle.fill", subtitle: "Signed in", chevron: true),
            text("Notifications", icon: "bell.badge.fill", chevron: true),
            text("Privacy & Security", icon: "lock.fill", chevron: true),
            text("General", icon: "gearshape.fill", chevron: true),
            text("Wi-Fi", icon: "wifi", detail: "Home", chevron: true),
            text("Bluetooth", icon: "wave.3.right", detail: "On", chevron: true),
            toggle("Airplane Mode", icon: "airplane", isOn: false),
            toggle("Low Power Mode", icon: "battery.25percent", isOn: false),
            toggle("Dark Appearance", icon: "moon.fill", isOn: true),
            text("About", icon: "info.circle.fill", subtitle: "Version 1.0", chevron: true),
            text("Sign out", icon: "arrow.right.square.fill", enabled: false),
        ]
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension UIKitPinTableViewDemo: UIKitPinTableViewDelegate {
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
