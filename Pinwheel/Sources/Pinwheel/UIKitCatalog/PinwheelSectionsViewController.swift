import UIKit

protocol PinwheelSectionsViewControllerDelegate: AnyObject {
    func pinWheelSectionsViewController(_ pinWheelSectionsViewController: PinwheelSectionsViewController, didSelectItemAtIndex index: Int)
}

class PinwheelSectionsViewController: UIViewController {
    weak var delegate: PinwheelSectionsViewControllerDelegate?

    let items: [UIKitPinTextTableViewItem]
    init(items: [UIKitPinTextTableViewItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sectionsTableView = UIKitPinTableView(items: items)
        sectionsTableView.selectedIndexPath = IndexPath(row: State.lastSelectedSection, section: 0)
        sectionsTableView.delegate = self
        view.addSubview(sectionsTableView)
        sectionsTableView.fillInSuperview()
    }
}

extension PinwheelSectionsViewController: UIKitPinTableViewDelegate {
    func tableView(_ tableView: UIKitPinTableView, didSwitchItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndex index: Int) {        
    }

    func tableView(_ tableView: UIKitPinTableView, didSelectItemAtIndex index: Int) {
        self.delegate?.pinWheelSectionsViewController(self, didSelectItemAtIndex: index)
    }
}
