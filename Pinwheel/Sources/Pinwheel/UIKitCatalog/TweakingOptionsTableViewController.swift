import UIKit

protocol TweakingOptionsTableViewControllerDelegate: AnyObject {
    func tweakingOptionsTableViewControllerDidDismiss(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController)
    func tweakingOptionsTableViewController(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController, didSelectDevice device: Device)
}

class TweakingOptionsTableViewController: ScrollViewController {
    // MARK: - Internal properties

    weak var delegate: TweakingOptionsTableViewControllerDelegate?

    // MARK: - Private properties

    private var tweaks: [Tweak]

    lazy var items: [UIKitPinTableViewItem] = {
        let items: [UIKitPinTableViewItem] = tweaks.compactMap {
            if $0 is TextTweak {
                return UIKitPinTextTableViewItem(title: $0.title, subtitle: $0.description)
            } else if $0 is BoolTweak {
                let boolItem = UIKitPinBoolTableViewItem(title: $0.title, subtitle:  $0.description)
                boolItem.isOn = ($0 as? BoolTweak)?.isOn ?? false
                return boolItem
            } else {
                return nil
            }
        }
        return items
    }()

    private lazy var tableView: UIKitPinTableView = {
        let view = UIKitPinTableView(dataSource: self)
        view.delegate = self
        return view
    }()

    private lazy var devicesTableView: UIKitPinTableView = {
        var items = [UIKitPinTextTableViewItem]()
        let currentBounds = UIScreen.main.bounds

        Device.all.forEach { device in
            var item = UIKitPinTextTableViewItem(title: device.title)

            if device.traits.userInterfaceIdiom == .phone && device.frame.size == currentBounds.size {
                item.title = "(Current) \(device.title)"
            }

            item.isEnabled = device.isEnabled
            items.append(item)
        }

        let tableView = UIKitPinTableView(items: items)
        tableView.delegate = self
        return tableView
    }()

    private lazy var selectorTitleView: SelectorTitleView = {
        let titleView = SelectorTitleView(heading: "Device")
        titleView.delegate = self
        return titleView
    }()

    // MARK: - Init

    init(tweaks: [Tweak]) {
        self.tweaks = tweaks
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        view.insertSubview(tableView, belowSubview: topShadowView)
        NSLayoutConstraint.activate([
            topShadowView.bottomAnchor.constraint(equalTo: view.topAnchor),

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let interfaceBackgroundColor: UIColor = .primaryBackground
        view.backgroundColor = interfaceBackgroundColor
        tableView.backgroundColor = interfaceBackgroundColor
        devicesTableView.backgroundColor = interfaceBackgroundColor

        navigationItem.titleView = selectorTitleView

        if let deviceIndex = State.selectedDeviceForCurrentIndexPath, deviceIndex < Device.all.count {
            selectorTitleView.title = Device.all[deviceIndex].title
        } else {
            selectorTitleView.title = "Choose a device"
        }
    }

    // MARK: - Private methods

    private func showDevicesViewController() {
        selectorTitleView.arrowDirection = .up

        guard devicesTableView.superview == nil else { return }

        view.addSubview(devicesTableView)
        devicesTableView.fillInSuperview()
        devicesTableView.alpha = 0.6
        devicesTableView.frame.origin.y = -.spacingXXL

        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            self?.devicesTableView.alpha = 1
        })

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 1,
            options: [],
            animations: { [weak self] in
                self?.devicesTableView.frame.origin.y = 0
            }
        )
    }

    private func hideDevicesViewController() {
        selectorTitleView.arrowDirection = .down
        tableView.alpha = 0

        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: ({ [weak self] in
            self?.devicesTableView.frame.origin.y = -.spacingXXL
            self?.devicesTableView.alpha = 0
        }), completion: ({ [weak self] _ in
            guard self?.devicesTableView.superview != nil else { return }

            self?.devicesTableView.removeFromSuperview()
        }))

        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.tableView.alpha = 1
        })
    }
}

// MARK: - SelectorTitleViewDelegate

extension TweakingOptionsTableViewController: SelectorTitleViewDelegate {
    func selectorTitleViewDidSelectButton(_ view: SelectorTitleView) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if view.arrowDirection == .up {
            hideDevicesViewController()
        } else {
            showDevicesViewController()
        }
    }

}

// MARK: - UIKitPinTableViewDelegate

extension TweakingOptionsTableViewController: UIKitPinTableViewDelegate {
    func tableView(_ tableView: UIKitPinTableView, didSwitchItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndex index: Int) {
        if var tweak = (tweaks[index] as? BoolTweak) {
            tweak.action(boolTableViewItem.isOn)
            tweak.isOn = boolTableViewItem.isOn
            tweaks[index] = tweak

            if let boolItem = items[index] as? UIKitPinBoolTableViewItem {
                boolItem.isOn = tweak.isOn
                items[index] = boolItem
            }
        }
    }
    
    func tableView(_ tableView: UIKitPinTableView, didSelectItemAtIndex index: Int) {
        if tableView == devicesTableView {
            let device = Device.all[index]
            selectorTitleView.title = device.title
            hideDevicesViewController()
            State.selectedDeviceForCurrentIndexPath = index
            delegate?.tweakingOptionsTableViewController(self, didSelectDevice: device)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.delegate?.tweakingOptionsTableViewControllerDidDismiss(self)
            }
        } else {
            if let voidTweak = tweaks[index] as? TextTweak {
                voidTweak.action()
            }
            delegate?.tweakingOptionsTableViewControllerDidDismiss(self)
        }
    }
}

extension TweakingOptionsTableViewController: UIKitPinTableViewDataSource {
    func tableViewNumberOfItems(_ tableView: UIKitPinTableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UIKitPinTableView, itemAtIndex index: Int) -> any UIKitPinTableViewItem {
        return items[index]
    }
}
