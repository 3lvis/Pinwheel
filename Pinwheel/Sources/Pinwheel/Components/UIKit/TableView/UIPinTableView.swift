import UIKit

public protocol UIPinTableViewDelegate: AnyObject {
    func tableView(_ tableView: UIPinTableView, didSelectItemAtIndex index: Int)
    func tableView(_ tableView: UIPinTableView, didSwitchItem boolTableViewItem: UIPinBoolTableViewItem, atIndex index: Int)
    func tableViewDidSelectFailedStateAction(_ tableView: UIPinTableView)
}

public extension UIPinTableViewDelegate {
    func tableView(_ tableView: UIPinTableView, didSwitchItem boolTableViewItem: UIPinBoolTableViewItem, atIndex index: Int) {}
    func tableViewDidSelectFailedStateAction(_ tableView: UIPinTableView) { }
}

public protocol UIPinTableViewDataSource: AnyObject {
    func tableViewNumberOfItems(_ tableView: UIPinTableView) -> Int
    func tableView(_ tableView: UIPinTableView, itemAtIndex index: Int) -> UIPinTableViewItem
}

public enum UIPinTableViewState {
    case loading(title: String, subtitle: String)
    case loaded([UIPinTableViewItem])
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

/// Stays UIKit: cell recycling, the dataSource/delegate contract, `UISwitch` items
/// and the A–Z section indexer have no `List` equivalent with comparable perf.
open class UIPinTableView: ShadowScrollView {
    public static let estimatedRowHeight: CGFloat = 60.0
    open var selectedIndexPath: IndexPath?

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.estimatedRowHeight = UIPinTableView.estimatedRowHeight
        tableView.separatorColor = .secondaryBackground
        tableView.separatorInset = .leadingInset(frame.width)
        return tableView
    }()

    private var usingShadowWhenScrolling: Bool = false

    public weak var delegate: UIPinTableViewDelegate?
    private weak var dataSource: UIPinTableViewDataSource?

    public var isScrollEnabled: Bool = true {
        didSet {
            tableView.isScrollEnabled = isScrollEnabled
        }
    }

    public var state: UIPinTableViewState = .loaded([UIPinTableViewItem]()) {
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

    lazy var stateView: UIPinStateView = {
        let view = UIPinStateView()
        view.delegate = self
        view.alpha = 0
        return view
    }()

    public init(dataSource: UIPinTableViewDataSource, usingShadowWhenScrolling: Bool = false) {
        self.usingShadowWhenScrolling = usingShadowWhenScrolling
        self.dataSource = dataSource
        super.init(frame: .zero)
        setup()
    }

    private var items = [UIPinTableViewItem]()
    public init(items: [UIPinTableViewItem] = [UIPinTableViewItem](), usingShadowWhenScrolling: Bool = false) {
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
        tableView.register(UIPinTableViewCell.self)
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

extension UIPinTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item: UIPinTableViewItem
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

extension UIPinTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dataSource = self.dataSource {
            return dataSource.tableViewNumberOfItems(self)
        } else {
            return items.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UIPinTableViewCell.self, for: indexPath)
        cell.delegate = self

        let item: UIPinTableViewItem
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

extension UIPinTableView: UIPinTableViewCellDelegate {
    public func tableViewCell(_ tableViewCell: UIPinTableViewCell, didChangeBoolTableViewItem boolTableViewItem: UIPinBoolTableViewItem, atIndexPath indexPath: IndexPath) {
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.delegate?.tableView(self, didSwitchItem: boolTableViewItem, atIndex: indexPath.row)
    }
}

extension UIPinTableView: UIPinStateViewDelegate {
    public func stateViewDidSelectAction(_ stateView: UIPinStateView) {
        self.delegate?.tableViewDidSelectFailedStateAction(self)
    }
}
