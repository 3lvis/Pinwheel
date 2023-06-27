import UIKit
import Designable

struct ColorItem {
    let color: UIColor
    let title: String
}

public class ColorDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    lazy var tableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.rowHeight = 30
        return view
    }()

    lazy var items: [ColorItem] = {
        return [
            ColorItem(color: .primaryText, title: "primaryText"),
            ColorItem(color: .secondaryText, title: "secondaryText"),
            ColorItem(color: .tertiaryText, title: "tertiaryText"),

            ColorItem(color: .primaryBackground, title: ""),

            ColorItem(color: .primaryAction, title: "primaryAction"),
            ColorItem(color: .criticalAction, title: "criticalAction"),

            ColorItem(color: .primaryBackground, title: ""),

            ColorItem(color: .primaryBackground, title: "primaryBackground"),
            ColorItem(color: .secondaryBackground, title: "secondaryBackground"),
            ColorItem(color: .tertiaryBackground, title: ".tertiaryBackground"),
            ColorItem(color: .criticalBackground, title: ".criticalBackground")
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

extension ColorDesignableView: UITableViewDataSource {
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
        cell.textLabel?.font = UIFont.subheadline
        cell.selectionStyle = .none

        return cell
    }
}
