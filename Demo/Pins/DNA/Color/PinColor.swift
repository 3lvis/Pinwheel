import UIKit
import Pinwheel

struct ColorItem {
    let color: UIColor
    let title: String
}

class PinColor: View {
    lazy var tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.rowHeight = 30
        return view
    }()

    lazy var items: [ColorItem] = {
        return [
            ColorItem(color: .primaryText, title: "Primary Text"),
            ColorItem(color: .secondaryText, title: "Secondary Text"),
            ColorItem(color: .tertiaryText, title: "Tertiary Text"),
            ColorItem(color: .actionText, title: "Action Text"),
            ColorItem(color: .criticalText, title: "Critical Text"),
            ColorItem(color: .primaryBackground, title: "Primary Background"),
            ColorItem(color: .secondaryBackground, title: "Secondary Background"),
            ColorItem(color: .actionBackground, title: "Action Background"),
            ColorItem(color: .criticalBackground, title: "Critical Background")
        ]
    }()

    override func setup() {
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

extension PinColor: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.backgroundColor = item.color
        let title = item.title.capitalizingFirstLetter + "  "
        let attributedTitle = NSMutableAttributedString(string: title)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: title.count))
        let whiteTitle = NSMutableAttributedString(string: title)
        whiteTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: title.count))
        attributedTitle.append(whiteTitle)
        cell.textLabel?.attributedText = attributedTitle
        cell.textLabel?.font = UIFont.subtitle
        cell.selectionStyle = .none

        return cell
    }
}
