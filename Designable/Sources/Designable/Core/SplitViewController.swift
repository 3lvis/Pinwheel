import UIKit

class SplitViewController: UISplitViewController {
    lazy var alternativeViewController: UIViewController = {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .primaryBackground

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        viewController.view.addGestureRecognizer(doubleTap)
        return viewController
    }()

    public convenience init(masterViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)

        viewControllers = [masterViewController, alternativeViewController]
        setup()
    }

    public convenience init(detailViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)

        viewControllers = [alternativeViewController, detailViewController]
        setup()
    }

    func setup() {
        preferredDisplayMode = .oneBesideSecondary
    }

    @objc func didDoubleTap() {
        State.lastSelectedIndexPath = nil
        dismiss(animated: true, completion: nil)
    }
}
