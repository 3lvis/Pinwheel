import UIKit

protocol PinWheelSectionsViewControllerDelegate: AnyObject {
    func pinWheelSectionsViewController(_ pinWheelSectionsViewController: PinWheelSectionsViewController, didSelectItemAtIndex index: Int)
}

class PinWheelSectionsViewController: UIViewController {
    weak var delegate: PinWheelSectionsViewControllerDelegate?

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
        let sectionsTableView = TableView(items: items)
        sectionsTableView.selectedIndexPath = IndexPath(row: State.lastSelectedSection, section: 0)
        sectionsTableView.delegate = self
        view.addSubview(sectionsTableView)
        sectionsTableView.fillInSuperview()
    }
}

extension PinWheelSectionsViewController: TableViewDelegate {
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int) {
        self.delegate?.pinWheelSectionsViewController(self, didSelectItemAtIndex: index)
    }
}
