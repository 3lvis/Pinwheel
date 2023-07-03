import UIKit

public protocol BottomSheetDelegate: AnyObject {
    /// Called by the BottomSheet *throughout* actions intended to dismiss the BottomSheet.
    /// The action performed by the user may not end in dismissal. The delegate should
    /// be consistent in the returned value.
    func bottomSheetShouldDismiss(_ bottomSheet: BottomSheet) -> Bool

    /// Called by the BottomSheet after the user has performed an action that would normally
    /// cause the BottomSheet to be dismissed, but `bottomSheetShouldDismiss(:)` prevented this
    /// from happening.
    func bottomSheetDidCancelDismiss(_ bottomSheet: BottomSheet)

    func bottomSheet(_ bottomSheet: BottomSheet, willDismissBy action: BottomSheetDismissAction)
    func bottomSheet(_ bottomSheet: BottomSheet, didDismissBy action: BottomSheetDismissAction)
}

public enum BottomSheetState {
    case expanded
    case compact
    case dismissed
}

public enum BottomSheetDismissAction {
    case tap
    case drag
    case none
}

public enum BottomSheetDraggableArea {
    case everything
    case navigationBar
    case topArea(height: CGFloat)
    case customRect(CGRect)
}

public class BottomSheet: UIViewController {
    // MARK: - Public properties

    private let rootViewController: UIViewController
    public weak var delegate: BottomSheetDelegate?

    public var state: BottomSheetState {
        get { transitionDelegate.presentationController?.state ?? .dismissed }
        set {
            transitionDelegate.presentationController?.state = newValue
            if !isDefaultPresentationStyle && newValue == .dismissed {
                delegate?.bottomSheet(self, didDismissBy: .none)
                dismiss(animated: true, completion: nil)
            }
        }
    }

    var draggableRect: CGRect? {
        switch draggableArea {
        case .everything:
            return nil
        case .navigationBar:
            guard let navigationController = rootViewController as? UINavigationController else { return nil }
            let navBarFrame = navigationController.navigationBar.bounds
            let draggableBounds = CGRect(origin: navBarFrame.origin, size: CGSize(width: navBarFrame.width, height: navBarFrame.height + notchHeight))
            return draggableBounds
        case .topArea(let height):
            let rootControllerWidth = rootViewController.view.bounds.width
            return CGRect(origin: .zero, size: CGSize(width: rootControllerWidth, height: notchHeight + height))
        case .customRect(let customRect):
            return CGRect(origin: CGPoint(x: customRect.minX, y: customRect.minY + notchHeight), size: customRect.size)
        }
    }

    // MARK: - Private properties

    private let transitionDelegate: BottomSheetTransitioningDelegate
    private let draggableArea: BottomSheetDraggableArea

    private let cornerRadius: CGFloat = 42
    private let compactHeight: CGFloat
    private let notchHeight: CGFloat = 20
    private var isDefaultPresentationStyle: Bool { modalPresentationStyle == .custom }

    private let notchView = NotchView()

    private var isNotchHidden: Bool {
        get { notchView.isHandleHidden }
        set { notchView.isHandleHidden = newValue }
    }

    public init(rootViewController: UIViewController, compactHeight: CGFloat = -999, draggableArea: BottomSheetDraggableArea = .everything) {
        self.rootViewController = rootViewController
        self.transitionDelegate = BottomSheetTransitioningDelegate()
        self.draggableArea = draggableArea
        self.compactHeight = compactHeight
        super.init(nibName: nil, bundle: nil)
        transitionDelegate.presentationControllerDelegate = self
        transitioningDelegate = transitionDelegate
        modalPresentationStyle = .custom
    }

    public convenience init(view: UIView, compactHeight: CGFloat = -999, draggableArea: BottomSheetDraggableArea = .everything) {
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .primaryBackground
        rootViewController.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillInSuperview()

        self.init(rootViewController: rootViewController, compactHeight: compactHeight, draggableArea: draggableArea)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = rootViewController.view.backgroundColor ?? .primaryBackground
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notchView)

        addChild(rootViewController)
        view.insertSubview(rootViewController.view, belowSubview: notchView)
        rootViewController.didMove(toParent: self)
        rootViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            notchView.heightAnchor.constraint(equalToConstant: notchHeight),
            notchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notchView.topAnchor.constraint(equalTo: view.topAnchor),

            rootViewController.view.topAnchor.constraint(equalTo: notchView.bottomAnchor),
            rootViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - BottomSheetDismissalDelegate

extension BottomSheet: BottomSheetPresentationControllerDelegate {
    func bottomSheetPresentationControllerCompactHeight(_ presentationController: BottomSheetPresentationController) -> CGFloat {
        if compactHeight == -999 {
            return rootViewController.view.frame.height * 0.4
        } else {
            return compactHeight
        }
    }

    func bottomSheetPresentationControllerShouldDismiss(_ presentationController: BottomSheetPresentationController) -> Bool {
        return delegate?.bottomSheetShouldDismiss(self) ?? true
    }

    func bottomSheetPresentationControllerDidCancelDismiss(_ presentationController: BottomSheetPresentationController) {
        delegate?.bottomSheetDidCancelDismiss(self)
    }

    func bottomSheetPresentationController(_ presentationController: BottomSheetPresentationController, willDismissPresentedViewController presentedViewController: UIViewController, by action: BottomSheetDismissAction) {
        delegate?.bottomSheet(self, willDismissBy: action)
    }

    func bottomSheetPresentationController(_ presentationController: BottomSheetPresentationController, didDismissPresentedViewController presentedViewController: UIViewController, by action: BottomSheetDismissAction) {
        delegate?.bottomSheet(self, didDismissBy: action)
    }
}
