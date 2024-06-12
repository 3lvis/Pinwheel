import UIKit

public class PinwheelViewController<View: UIView>: UIViewController {

    private var presentationStyle: PresentationStyle
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask = .all
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool

    public init(presentationStyle: PresentationStyle = .fullscreen,
                supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
                constrainToTopSafeArea: Bool = true,
                constrainToBottomSafeArea: Bool = true) {
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
                sheetPresentationController?.preferredCornerRadius = .spacingXL
                sheetPresentationController?.prefersGrabberVisible = true
            case .large:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.large()]
                sheetPresentationController?.preferredCornerRadius = .spacingXL
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

    var tweakingNavigationController: NavigationController?

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let viewController = BasePinwheelViewController<View>(
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
        let tweaks = tweakablePlaygroundView?.tweaks ?? [Tweak]()
        let overlayView = CornerAnchoringView()
        overlayView.itemsCount = tweaks.count
        overlayView.delegate = self
        view.addSubview(overlayView)
        overlayView.fillInSuperview()
    }
}

extension PinwheelViewController: CornerAnchoringViewDelegate {
    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView) {
        if let controller = tweakingNavigationController {
            if #available(iOS 15.0, *) {
                controller.sheetPresentationController?.detents = [.medium()]
                controller.sheetPresentationController?.preferredCornerRadius = .spacingXL
                controller.sheetPresentationController?.prefersGrabberVisible = true
            }
            present(controller, animated: true)
        } else {
            let tweakablePlaygroundView = (childViewController?.playgroundView as? Tweakable) ?? (self as? Tweakable)
            let tweaks = tweakablePlaygroundView?.tweaks ?? [Tweak]()
            let tweakingController = TweakingOptionsTableViewController(tweaks: tweaks)
            tweakingController.delegate = self
            let tweakingNavigationController = NavigationController(rootViewController: tweakingController)
            tweakingNavigationController.hairlineIsHidden = true

            if #available(iOS 15.0, *) {
                tweakingNavigationController.sheetPresentationController?.detents = [.medium()]
                tweakingNavigationController.sheetPresentationController?.preferredCornerRadius = .spacingXL
                tweakingNavigationController.sheetPresentationController?.prefersGrabberVisible = true
            }
            self.tweakingNavigationController = tweakingNavigationController
            present(tweakingNavigationController, animated: true)
        }
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
