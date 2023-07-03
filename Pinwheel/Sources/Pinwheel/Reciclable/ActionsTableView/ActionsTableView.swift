import UIKit

public final class ActionsTableView: UIView {
    let rowHeight: CGFloat = 68

    // MARK: - Private properties
    private lazy var headerView: ActionHeaderView = {
        let view = ActionHeaderView(withAutoLayout: true)
        view.configure(title: self.title)
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = rowHeight
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.register(ActionCell.self)
        tableView.contentInset = UIEdgeInsets(top: 7)
        tableView.isScrollEnabled = false
        return tableView
    }()

    private var actions: [Action]

    var title: String
    public init(title: String, actions: [Action]) {
        self.title = title
        self.actions = actions
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        addSubview(headerView)
        addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public func totalHeight(inView view: UIView) -> CGFloat {
        let width = view.safeAreaLayoutGuide.layoutFrame.width
        let notchHeight = 20.0
        let headerViewHeight = headerView.height(width: width) + notchHeight
        let tableViewHeight = rowHeight * CGFloat(actions.count)
        return headerViewHeight + tableViewHeight + view.layoutMargins.bottom
    }
}

// MARK: - UITableViewDataSource

extension ActionsTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ActionCell.self, for: indexPath)
        let action = actions[indexPath.row]
        cell.configure(withTitle: action.title, isCritical: action.isCritical)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ActionsTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = actions[indexPath.row]
        action.action()
    }
}
