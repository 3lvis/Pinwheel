import UIKit
import Pinwheel

class UIPinDataSourceTableViewDemo: UIPinView, Tweakable {
    private var rowCount = 6

    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Add row") {
                self.rowCount += 1
                self.tableView.reloadData()
            },
            TextTweak(title: "Remove row") {
                self.rowCount = max(0, self.rowCount - 1)
                self.tableView.reloadData()
            }
        ]
    }()

    lazy var tableView: UIPinTableView = {
        let view = UIPinTableView(dataSource: self)
        view.delegate = self
        return view
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension UIPinDataSourceTableViewDemo: UIPinTableViewDataSource {
    func tableViewNumberOfItems(_ tableView: UIPinTableView) -> Int {
        return rowCount
    }

    func tableView(_ tableView: UIPinTableView, itemAtIndex index: Int) -> UIPinTableViewItem {
        return UIPinTextTableViewItem(title: "Row \(index + 1)", subtitle: "Served by the data source")
    }
}

extension UIPinDataSourceTableViewDemo: UIPinTableViewDelegate {
    func tableView(_ tableView: UIPinTableView, didSelectItemAtIndex index: Int) {
        print("Selected row \(index + 1)")
    }
}
