import UIKit

protocol TweakingOptionsTableViewControllerDelegate: AnyObject {
    func tweakingOptionsTableViewControllerDidDismiss(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController)
    func tweakingOptionsTableViewController(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController, didSelectDevice device: Device)
}

class TweakingOptionsTableViewController: ScrollViewController {
    // MARK: - Internal properties

    weak var delegate: TweakingOptionsTableViewControllerDelegate?

    // MARK: - Private properties

    private let tweaks: [Tweak]

    private lazy var tableView: TableView = {
        let items = tweaks.map { TextTableViewItem(title: $0.title, subtitle: $0.description) }
        let view = TableView(items: items)
        view.delegate = self
        return view
    }()

    private lazy var devicesTableView: TableView = {
        var items = [TextTableViewItem]()
        Device.all.forEach { device in
            var item = TextTableViewItem(title: device.title)
            item.isEnabled = device.isEnabled
            items.append(item)
        }

        let tableView = TableView(items: items)
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
        devicesTableView.frame.origin.y = -.spacingXL

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
            self?.devicesTableView.frame.origin.y = -.spacingXL
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

// MARK: - TableViewDelegate

extension TweakingOptionsTableViewController: TableViewDelegate {
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int) {
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
            let tweak = tweaks[index]
            _ = tweak.action(())
            delegate?.tweakingOptionsTableViewControllerDidDismiss(self)
        }
    }
}
