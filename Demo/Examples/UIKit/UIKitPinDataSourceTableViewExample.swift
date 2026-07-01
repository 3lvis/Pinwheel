import UIKit
import Pinwheel

class UIKitPinDataSourceTableViewExample: UIKitPinView, Tweakable {
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

    lazy var tableView: UIKitPinTableView = {
        let view = UIKitPinTableView(dataSource: self)
        view.delegate = self
        return view
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension UIKitPinDataSourceTableViewExample: UIKitPinTableViewDataSource {
    func tableViewNumberOfItems(_ tableView: UIKitPinTableView) -> Int {
        return rowCount
    }

    func tableView(_ tableView: UIKitPinTableView, itemAtIndex index: Int) -> UIKitPinTableViewItem {
        return UIKitPinTextTableViewItem(title: "Row \(index + 1)", subtitle: "Served by the data source")
    }
}

extension UIKitPinDataSourceTableViewExample: UIKitPinTableViewDelegate {
    func tableView(_ tableView: UIKitPinTableView, didSelectItemAtIndex index: Int) {
        print("Selected row \(index + 1)")
    }
}
