import UIKit

public protocol TableViewDelegate: AnyObject {
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int)
    func tableView(_ tableView: TableView, didSwitchItem boolTableViewItem: BoolTableViewItem, atIndex index: Int)
}

open class TableView: ShadowScrollView {
    public static let estimatedRowHeight: CGFloat = 60.0
    open var selectedIndexPath: IndexPath?
    open var items: [TableViewItem]

    // MARK: - Internal properties

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.estimatedRowHeight = TableView.estimatedRowHeight
        tableView.separatorColor = .secondaryBackground
        tableView.separatorInset = .leadingInset(frame.width)
        tableView.contentInset = UIEdgeInsets(top: .spacingS, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    private var usingShadowWhenScrolling: Bool = false

    public weak var delegate: TableViewDelegate?

    // MARK: - Setup

    public init(items: [TableViewItem], usingShadowWhenScrolling: Bool = false) {
        self.usingShadowWhenScrolling = usingShadowWhenScrolling
        self.items = items
        super.init(frame: .zero)
        setup()
    }

    public override init(frame: CGRect) {
        self.items = [TableViewItem]()
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.items = [TableViewItem]()
        super.init(frame: .zero)
        setup()
    }

    public func reloadData() {
        tableView.reloadData()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .primaryBackground
        tableView.register(TableViewCell.self)

        if usingShadowWhenScrolling {
            insertSubview(tableView, belowSubview: topShadowView)
            let anchor = topShadowView.bottomAnchor.constraint(equalTo: topAnchor)
            anchor.isActive = true
        } else {
            addSubview(tableView)
        }
        tableView.fillInSuperview()
    }
}

// MARK: - UITableViewDelegate
extension TableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
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
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(TableViewCell.self, for: indexPath)
        cell.delegate = self

        let item = items[indexPath.row]
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
