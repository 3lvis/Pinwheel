import Pinwheel

private struct ViewModel: BasicTableViewCellViewModel {
    var title: String
    let subtitle: String? = nil
    let detailText: String? = nil
    let hasChevron: Bool = false
}

class PinBasicTableViewCell: View {
    private let viewModels = [
        ViewModel(title: "Hagemøbler"),
        ViewModel(title: "Kattepuser"),
        ViewModel(title: "Mac Mini Pro"),
        ViewModel(title: "Mac Pro Mini"),
        ViewModel(title: "Mac Pro Max")
    ]

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.register(BasicTableViewCell.self)
        tableView.separatorInset = .leadingInset(frame.width)
        tableView.backgroundColor = .primaryBackground
        tableView.separatorColor = .secondaryBackground
        return tableView
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension PinBasicTableViewCell: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastCell = indexPath.row == (viewModels.count - 1)
        if isLastCell {
            cell.separatorInset = .leadingInset(frame.width)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PinBasicTableViewCell: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(BasicTableViewCell.self, for: indexPath)
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
}