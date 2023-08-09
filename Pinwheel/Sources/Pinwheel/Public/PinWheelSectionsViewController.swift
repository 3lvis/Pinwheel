import UIKit

protocol PinWheelSectionsViewControllerDelegate: AnyObject {
    func pinWheelSectionsViewController(_ pinWheelSectionsViewController: PinWheelSectionsViewController, didSelectItemAtIndex index: Int)
}

class PinWheelSectionsViewController: UIViewController {
    weak var delegate: PinWheelSectionsViewControllerDelegate?

    let items: [BasicTableViewItem]
    init(items: [BasicTableViewItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let sectionsTableView = BasicTableView(items: items)
        sectionsTableView.selectedIndexPath = IndexPath(row: State.lastSelectedSection, section: 0)
        sectionsTableView.delegate = self
        view.addSubview(sectionsTableView)
        sectionsTableView.fillInSuperview()
    }
}

extension PinWheelSectionsViewController: BasicTableViewDelegate {
    func basicTableView(_ basicTableView: BasicTableView, didSelectItemAtIndex index: Int) {
        self.delegate?.pinWheelSectionsViewController(self, didSelectItemAtIndex: index)
    }
}
