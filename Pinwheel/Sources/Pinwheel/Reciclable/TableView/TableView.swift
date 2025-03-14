import UIKit

public protocol TableViewDelegate: AnyObject {
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int)
    func tableView(_ tableView: TableView, didSwitchItem boolTableViewItem: BoolTableViewItem, atIndex index: Int)
    func tableViewDidSelectFailedStateAction(_ tableView: TableView)
}

public extension TableViewDelegate {
    func tableView(_ tableView: TableView, didSwitchItem boolTableViewItem: BoolTableViewItem, atIndex index: Int) {}
    func tableViewDidSelectFailedStateAction(_ tableView: TableView) { }
}

public protocol TableViewDataSource: AnyObject {
    func tableViewNumberOfItems(_ tableView: TableView) -> Int
    func tableView(_ tableView: TableView, itemAtIndex index: Int) -> TableViewItem
}

public enum TableViewState {
    case loading(title: String, subtitle: String)
    case loaded([TableViewItem])
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

open class TableView: ShadowScrollView {
    public static let estimatedRowHeight: CGFloat = 60.0
    open var selectedIndexPath: IndexPath?

    // MARK: - Internal properties

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.estimatedRowHeight = TableView.estimatedRowHeight
        tableView.separatorColor = .secondaryBackground
        tableView.separatorInset = .leadingInset(frame.width)
        return tableView
    }()

    private var usingShadowWhenScrolling: Bool = false

    public weak var delegate: TableViewDelegate?
    private weak var dataSource: TableViewDataSource?

    public var isScrollEnabled: Bool = true {
        didSet {
            tableView.isScrollEnabled = isScrollEnabled
        }
    }

    public var state: TableViewState = .loaded([TableViewItem]()) {
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

    lazy var stateView: StateView = {
        let view = StateView()
        view.delegate = self
        view.alpha = 0
        return view
    }()

    // MARK: - Setup

    public init(dataSource: TableViewDataSource, usingShadowWhenScrolling: Bool = false) {
        self.usingShadowWhenScrolling = usingShadowWhenScrolling
        self.dataSource = dataSource
        super.init(frame: .zero)
        setup()
    }

    private var items = [TableViewItem]()
    public init(items: [TableViewItem] = [TableViewItem](), usingShadowWhenScrolling: Bool = false) {
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
        tableView.register(TableViewCell.self)
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

// MARK: - UITableViewDelegate
extension TableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item: TableViewItem
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

// MARK: - UITableViewDataSource
extension TableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dataSource = self.dataSource {
            return dataSource.tableViewNumberOfItems(self)
        } else {
            return items.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(TableViewCell.self, for: indexPath)
        cell.delegate = self

        let item: TableViewItem
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

extension TableView: TableViewCellDelegate {
    public func tableViewCell(_ tableViewCell: TableViewCell, didChangeBoolTableViewItem boolTableViewItem: BoolTableViewItem, atIndexPath indexPath: IndexPath) {
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.delegate?.tableView(self, didSwitchItem: boolTableViewItem, atIndex: indexPath.row)
    }
}

extension TableView: TableViewDataSource {
    public func tableViewNumberOfItems(_ tableView: TableView) -> Int {
        return items.count
    }

    public func tableView(_ tableView: TableView, itemAtIndex index: Int) -> any TableViewItem {
        return items[index]
    }
}

extension TableView: StateViewDelegate {
    public func stateViewDidSelectAction(_ stateView: StateView) {
        self.delegate?.tableViewDidSelectFailedStateAction(self)
    }
}
