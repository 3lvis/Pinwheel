import UIKit

protocol PinwheelSectionsViewControllerDelegate: AnyObject {
    func pinWheelSectionsViewController(_ pinWheelSectionsViewController: PinwheelSectionsViewController, didSelectItemAtIndex index: Int)
}

class PinwheelSectionsViewController: UIViewController {
    weak var delegate: PinwheelSectionsViewControllerDelegate?

    let items: [TextTableViewItem]
    init(items: [TextTableViewItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sectionsTableView = TableView(dataSource: self)
        sectionsTableView.selectedIndexPath = IndexPath(row: State.lastSelectedSection, section: 0)
        sectionsTableView.delegate = self
        view.addSubview(sectionsTableView)
        sectionsTableView.fillInSuperview()
    }
}

extension PinwheelSectionsViewController: TableViewDelegate {
    func tableView(_ tableView: TableView, didSwitchItem boolTableViewItem: BoolTableViewItem, atIndex index: Int) {        
    }

    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int) {
        self.delegate?.pinWheelSectionsViewController(self, didSelectItemAtIndex: index)
    }
}

extension PinwheelSectionsViewController: TableViewDataSource {
    func tableViewNumberOfItems(_ tableView: TableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: TableView, itemAtIndex index: Int) -> TableViewItem {
        return items[index]
    }
}
