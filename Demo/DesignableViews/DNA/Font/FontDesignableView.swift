import UIKit

struct FontItem {
    let font: UIFont
    let title: String
}

public class FontDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    lazy var tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.rowHeight = 60
        return view
    }()

    lazy var items: [FontItem] = {
        return [
            FontItem(font: .body, title: "body"),
            FontItem(font: .bodyStrong, title: "bodyStrong"),

            FontItem(font: .detail, title: "detail"),
            FontItem(font: .detailStrong, title: "detailStrong"),

            FontItem(font: .caption, title: "caption"),
            FontItem(font: .captionStrong, title: "captionStrong"),
        ]
    }()

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    private func setup() {
        addSubview(tableView)
        tableView.dataSource = self
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        tableView.register(UITableViewCell.self)
    }
}

extension FontDesignableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title.capitalized
        cell.textLabel?.font = item.font
        cell.textLabel?.textColor = .primaryText
        cell.selectionStyle = .none

        return cell
    }
}
