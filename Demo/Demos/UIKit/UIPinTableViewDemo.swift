import UIKit
import Pinwheel

class UIPinTableViewDemo: UIPinView, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.tableView.state = .loading(title: DemoStateFixture.loadingTitle, subtitle: DemoStateFixture.loadingSubtitle)
            },
            TextTweak(title: "Loaded") {
                self.tableView.state = .loaded([UIPinTextTableViewItem(title: "Only value")])
            },
            TextTweak(title: "Empty") {
                self.tableView.state = .empty(title: DemoStateFixture.emptyTitle, subtitle: DemoStateFixture.emptySubtitle)
            },
            TextTweak(title: "Failed") {
                self.tableView.state = .failed(title: DemoStateFixture.failedTitle, subtitle: DemoStateFixture.failedSubtitle, actionTitle: DemoStateFixture.retryActionTitle)
            }
        ]
    }()

    lazy var tableView: UIPinTableView = {
        let view = UIPinTableView(items: items, usingShadowWhenScrolling: true)
        view.delegate = self
        return view
    }()

    lazy var items: [UIPinTableViewItem] = {
        @MainActor func text(_ title: String, icon: String? = nil, subtitle: String? = nil, detail: String? = nil, chevron: Bool = false, enabled: Bool = true) -> UIPinTextTableViewItem {
            let item = UIPinTextTableViewItem(title: title, subtitle: subtitle)
            item.icon = icon.flatMap { UIImage(systemName: $0) }
            item.detailText = detail
            item.hasChevron = chevron
            item.isEnabled = enabled
            return item
        }
        @MainActor func toggle(_ title: String, icon: String, isOn: Bool) -> UIPinBoolTableViewItem {
            let item = UIPinBoolTableViewItem(title: title)
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
            text("About", subtitle: "Version 1.0", chevron: true),
            text("Sign out", enabled: false),
        ]
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension UIPinTableViewDemo: UIPinTableViewDelegate {
    func tableView(_ tableView: Pinwheel.UIPinTableView, didSwitchItem boolTableViewItem: Pinwheel.UIPinBoolTableViewItem, atIndex index: Int) {
        let title = "Changed \(boolTableViewItem.title) to \(boolTableViewItem.isOn ? "on" : "off")"
        print(title)
    }
    
    func tableView(_ tableView: UIPinTableView, didSelectItemAtIndex index: Int) {
        let title = "Selected \((items[index] as? UIPinTextTableViewItem)?.title ?? "")"
        print(title)
    }

    func tableViewDidSelectFailedStateAction(_ tableView: UIPinTableView) {
        print("tapped!")
    }
}
