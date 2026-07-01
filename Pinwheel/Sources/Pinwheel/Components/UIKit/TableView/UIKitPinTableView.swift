import UIKit

public protocol UIKitPinTableViewDelegate: AnyObject {
    func tableView(_ tableView: UIKitPinTableView, didSelectItemAtIndex index: Int)
    func tableView(_ tableView: UIKitPinTableView, didSwitchItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndex index: Int)
    func tableViewDidSelectFailedStateAction(_ tableView: UIKitPinTableView)
}

public extension UIKitPinTableViewDelegate {
    func tableView(_ tableView: UIKitPinTableView, didSwitchItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndex index: Int) {}
    func tableViewDidSelectFailedStateAction(_ tableView: UIKitPinTableView) { }
}

public protocol UIKitPinTableViewDataSource: AnyObject {
    func tableViewNumberOfItems(_ tableView: UIKitPinTableView) -> Int
    func tableView(_ tableView: UIKitPinTableView, itemAtIndex index: Int) -> UIKitPinTableViewItem
}

public enum UIKitPinTableViewState {
    case loading(title: String, subtitle: String)
    case loaded([UIKitPinTableViewItem])
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

/// Stays UIKit: cell recycling, the dataSource/delegate contract, `UISwitch` items
/// and the A–Z section indexer have no `List` equivalent with comparable perf.
open class UIKitPinTableView: ShadowScrollView {
    public static let estimatedRowHeight: CGFloat = 60.0
    open var selectedIndexPath: IndexPath?

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.estimatedRowHeight = UIKitPinTableView.estimatedRowHeight
        tableView.separatorColor = .secondaryBackground
        tableView.separatorInset = .leadingInset(frame.width)
        return tableView
    }()

    private var usingShadowWhenScrolling: Bool = false

    public weak var delegate: UIKitPinTableViewDelegate?
    private weak var dataSource: UIKitPinTableViewDataSource?

    public var isScrollEnabled: Bool = true {
        didSet {
            tableView.isScrollEnabled = isScrollEnabled
        }
    }

    public var state: UIKitPinTableViewState = .loaded([UIKitPinTableViewItem]()) {
        didSet {
            switch state {
            case .loading(let title, let subtitle):
                tableView.alpha = 0
                stateView.state = .loading(title: title, subtitle: subtitle)
            case .loaded(let items):
                stateView.state = .loaded
                tableView.alpha = 1
                self.items = items
                self.tableView.reloadData()
            case .empty(let title, let subtitle):
                tableView.alpha = 0
                stateView.state = .empty(title: title, subtitle: subtitle)
            case .failed(let title, let subtitle, let actionTitle):
                tableView.alpha = 0
                stateView.state = .failed(title: title, subtitle: subtitle, actionTitle: actionTitle)
            }
        }
    }

    lazy var stateView: UIKitPinStateView = {
        let view = UIKitPinStateView()
        view.delegate = self
        view.alpha = 0
        return view
    }()

    public init(dataSource: UIKitPinTableViewDataSource, usingShadowWhenScrolling: Bool = false) {
        self.usingShadowWhenScrolling = usingShadowWhenScrolling
        self.dataSource = dataSource
        super.init(frame: .zero)
        setup()
    }

    private var items = [UIKitPinTableViewItem]()
    public init(items: [UIKitPinTableViewItem] = [UIKitPinTableViewItem](), usingShadowWhenScrolling: Bool = false) {
        self.items = items
        self.usingShadowWhenScrolling = usingShadowWhenScrolling
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func reloadData() {
        tableView.reloadData()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .primaryBackground
        tableView.register(UIKitPinTableViewCell.self)
        addSubview(stateView)

        if usingShadowWhenScrolling {
            insertSubview(tableView, belowSubview: topShadowView)
            let anchor = topShadowView.bottomAnchor.constraint(equalTo: topAnchor)
            anchor.isActive = true
        } else {
            addSubview(tableView)
        }
        stateView.fillInSuperview()
        tableView.fillInSuperview()
    }
}

extension UIKitPinTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item: UIKitPinTableViewItem
        if let dataSource = self.dataSource {
            item = dataSource.tableView(self, itemAtIndex: indexPath.row)
        } else {
            item = items[indexPath.row]
        }
        if item.isEnabled {
            delegate?.tableView(self, didSelectItemAtIndex: indexPath.row)
        }
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension UIKitPinTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dataSource = self.dataSource {
            return dataSource.tableViewNumberOfItems(self)
        } else {
            return items.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UIKitPinTableViewCell.self, for: indexPath)
        cell.delegate = self

        let item: UIKitPinTableViewItem
        if let dataSource = self.dataSource {
            item = dataSource.tableView(self, itemAtIndex: indexPath.row)
        } else {
            item = items[indexPath.row]
        }
        cell.selectedIndexPath = selectedIndexPath
        cell.isEnabled = item.isEnabled
        cell.indexPath = indexPath
        cell.tableViewItem = item

        return cell
    }
}

extension UIKitPinTableView: UIKitPinTableViewCellDelegate {
    public func tableViewCell(_ tableViewCell: UIKitPinTableViewCell, didChangeBoolTableViewItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndexPath indexPath: IndexPath) {
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.delegate?.tableView(self, didSwitchItem: boolTableViewItem, atIndex: indexPath.row)
    }
}

extension UIKitPinTableView: UIKitPinStateViewDelegate {
    public func stateViewDidSelectAction(_ stateView: UIKitPinStateView) {
        self.delegate?.tableViewDidSelectFailedStateAction(self)
    }
}
