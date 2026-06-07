import SwiftUI
import UIKit

public class PinwheelHostingViewController<Content: SwiftUI.View>: UIViewController {
    private let presentationStyle: PresentationStyle
    private var preferredInterfaceOrientation: UIInterfaceOrientationMask
    private let constrainToBottomSafeArea: Bool
    private let constrainToTopSafeArea: Bool
    private let rootView: Content

    private var contentViewController: UIViewController?
    private var tweakingNavigationController: NavigationController?

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return preferredInterfaceOrientation
    }

    public init(
        rootView: Content,
        presentationStyle: PresentationStyle = .fullscreen,
        supportedInterfaceOrientations: UIInterfaceOrientationMask = .all,
        constrainToTopSafeArea: Bool = true,
        constrainToBottomSafeArea: Bool = true
    ) {
        self.rootView = rootView
        self.presentationStyle = presentationStyle
        self.preferredInterfaceOrientation = supportedInterfaceOrientations
        self.constrainToTopSafeArea = constrainToTopSafeArea
        self.constrainToBottomSafeArea = constrainToBottomSafeArea

        super.init(nibName: nil, bundle: nil)

        configurePinwheelPresentationStyle(presentationStyle)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let contentViewController = makeContentViewController()
        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        self.contentViewController = contentViewController

        if let deviceIndex = State.selectedDeviceForCurrentIndexPath, deviceIndex < Device.all.count {
            let device = Device.all[deviceIndex]
            contentViewController.view.frame = device.frame
            contentViewController.view.autoresizingMask = device.autoresizingMask
            setOverrideTraitCollection(device.traits, forChild: contentViewController)
        } else {
            contentViewController.view.frame = view.bounds
            contentViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        let overlayView = CornerAnchoringView()
        overlayView.itemsCount = 0
        overlayView.delegate = self
        view.addSubview(overlayView)
        overlayView.fillInSuperview()
    }

    private func makeContentViewController() -> UIViewController {
        let container = UIViewController()
        container.view.backgroundColor = .primaryBackground

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .primaryBackground
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        container.addChild(hostingController)
        container.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: container)

        let topAnchor = constrainToTopSafeArea ? container.view.safeAreaLayoutGuide.topAnchor : container.view.topAnchor
        let bottomAnchor = constrainToBottomSafeArea ? container.view.safeAreaLayoutGuide.bottomAnchor : container.view.bottomAnchor

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        return container
    }
}

extension PinwheelHostingViewController: CornerAnchoringViewDelegate {
    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView) {
        if let controller = tweakingNavigationController {
            configureTweakingController(controller)
            present(controller, animated: true)
        } else {
            let tweakingController = TweakingOptionsTableViewController(tweaks: [])
            tweakingController.delegate = self
            let tweakingNavigationController = NavigationController(rootViewController: tweakingController)
            tweakingNavigationController.hairlineIsHidden = true
            configureTweakingController(tweakingNavigationController)
            self.tweakingNavigationController = tweakingNavigationController
            present(tweakingNavigationController, animated: true)
        }
    }

    func cornerAnchoringViewDidSelectCloseButton(_ cornerAnchoringView: CornerAnchoringView) {
        State.lastSelectedIndexPath = nil
        dismiss(animated: true, completion: nil)
    }

    private func configureTweakingController(_ controller: UIViewController) {
        if #available(iOS 15.0, *) {
            controller.sheetPresentationController?.detents = [.medium()]
            controller.sheetPresentationController?.preferredCornerRadius = .spacingXL
            controller.sheetPresentationController?.prefersGrabberVisible = true
        }
    }
}

extension PinwheelHostingViewController: TweakingOptionsTableViewControllerDelegate {
    func tweakingOptionsTableViewController(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController, didSelectDevice device: Device) {
        guard let contentViewController = contentViewController else { return }

        UIView.animate(withDuration: 0.3) {
            contentViewController.view.frame = device.frame
            contentViewController.view.autoresizingMask = device.autoresizingMask
            self.setOverrideTraitCollection(device.traits, forChild: contentViewController)
        }
    }

    func tweakingOptionsTableViewControllerDidDismiss(_ tweakingOptionsTableViewController: TweakingOptionsTableViewController) {
        dismiss(animated: true)
    }
}
