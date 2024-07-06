import UIKit
import Pinwheel

struct FontItem {
    let font: UIFont
    let title: String
}

class PinFont: View {
    lazy var tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.rowHeight = 60
        return view
    }()

    lazy var items: [FontItem] = {
        return [
            FontItem(font: .title, title: "Title"),
            FontItem(font: .subtitle, title: "Subtitle"),
            FontItem(font: .body, title: "Body"),
            FontItem(font: .footnote, title: "Footnote"),
            FontItem(font: .caption, title: "A caption awesome"),

            FontItem(font: .titleSemibold, title: "Title Semibold"),
            FontItem(font: .subtitleSemibold, title: "Subtitle Semibold"),
            FontItem(font: .bodySemibold, title: "Body Semibold"),
            FontItem(font: .footnoteSemibold, title: "Footnote Semibold"),
            FontItem(font: .captionSemibold, title: "A caption awesome semibold"),
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

extension PinFont: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title.capitalized
        cell.textLabel?.font = item.font
        cell.textLabel?.textColor = .primaryText
        cell.selectionStyle = .none

        return cell
    }
}
