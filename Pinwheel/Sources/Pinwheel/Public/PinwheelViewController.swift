import UIKit

public class PinwheelViewController<View: UIView>: UIViewController {

    private var dismissType: DismissType
    private var presentationStyle: PresentationStyle
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask = .all
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool

    public init(dismissType: DismissType = .doubleTap,
                presentationStyle: PresentationStyle = .large,
                supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
                constrainToTopSafeArea: Bool = true,
                constrainToBottomSafeArea: Bool = true) {
        self.dismissType = dismissType
        self.presentationStyle = presentationStyle
        self.preferredInterfaceOrientation = supportedInterfaceOrientations
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.constrainToTopSafeArea = constrainToTopSafeArea
        super.init(nibName: nil, bundle: nil)

        if #available(iOS 15.0, *) {
            switch presentationStyle {
            case .medium:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.medium()]
                sheetPresentationController?.preferredCornerRadius = 40
                sheetPresentationController?.prefersGrabberVisible = true
            case .large:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.large()]
                sheetPresentationController?.preferredCornerRadius = 40
                sheetPresentationController?.prefersGrabberVisible = true
            case .fullscreen:
                modalPresentationStyle = .fullScreen
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var childViewController: BasePinwheelViewController<View>?

    var playgroundView: View? {
        return childViewController?.playgroundView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let viewController = BasePinwheelViewController<View>(
            dismissType: dismissType,
            presentationStyle: presentationStyle,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea)
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        childViewController = viewController

        if let deviceIndex = State.selectedDeviceForCurrentIndexPath, deviceIndex < Device.all.count {
            let device = Device.all[deviceIndex]
            viewController.view.frame = device.frame
            viewController.view.autoresizingMask = device.autoresizingMask
            setOverrideTraitCollection(device.traits, forChild: viewController)
        }

        view.fillInSuperview()

        if let barButtonProvider = playgroundView as? BarButtonProvider {
            navigationItem.rightBarButtonItems = barButtonProvider.rightBarButtonItems
        }

        let tweakablePlaygroundView = (childViewController?.playgroundView as? Tweakable) ?? (self as? Tweakable)
        let options = tweakablePlaygroundView?.tweakingOptions ?? [TweakingOption]()
        let overlayView = CornerAnchoringView(showCloseButton: dismissType == .dismissButton)
        overlayView.itemsCount = options.count
        overlayView.delegate = self
        view.addSubview(overlayView)
        overlayView.fillInSuperview()
    }
}

extension PinwheelViewController: CornerAnchoringViewDelegate {
    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView) {
        let tweakablePlaygroundView = (childViewController?.playgroundView as? Tweakable) ?? (self as? Tweakable)
        let options = tweakablePlaygroundView?.tweakingOptions ?? [TweakingOption]()
        let tweakingController = TweakingOptionsTableViewController(options: options)
        tweakingController.delegate = self
        let navigationController = NavigationController(rootViewController: tweakingController)
        navigationController.hairlineIsHidden = true

        if #available(iOS 15.0, *) {
            navigationController.sheetPresentationController?.detents = [.medium()]
            navigationController.sheetPresentationController?.preferredCornerRadius = 40
            navigationController.sheetPresentationController?.prefersGrabberVisible = true
        }
        present(navigationController, animated: true)
    }

    func cornerAnchoringViewDidSelectCloseButton(_ cornerAnchoringView: CornerAnchoringView) {
        State.lastSelectedIndexPath = nil
        dismiss(animated: true, completion: nil)
    }
}

extension PinwheelViewController: TweakingOptionsTableViewControllerDelegate {
    func tweakingOptionsTableViewController(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController, didSelectDevice device: Device) {
        for child in children {
            UIView.animate(withDuration: 0.3) {
                child.view.frame = device.frame
                child.view.autoresizingMask = device.autoresizingMask
                self.setOverrideTraitCollection(device.traits, forChild: child)
            }
        }
    }

    func tweakingOptionsTableViewControllerDidDismiss(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController) {
        dismiss(animated: true)
    }
}
