import UIKit

/**
 The presentation controller is controlling how the bottom sheet is presented.
 This object operates together with the interaction controller to create the complete transition.

 When the presentation transition begins, this object will create a gesture controller and set its delegate to the interaction controller in order to interact with the transition animation.
 After the transition if finished, this objects becomes the gesture controllers delegate and is in control of the constraint during the presentation.

 At this point, only the presenting transition is made interactive because the presentation is it self an interactive way of dismissing the bottom sheet.
**/

protocol BottomSheetPresentationControllerDelegate: AnyObject {
    func bottomSheetPresentationControllerShouldDismiss(_ presentationController: BottomSheetPresentationController) -> Bool
    func bottomSheetPresentationControllerDidCancelDismiss(_ presentationController: BottomSheetPresentationController)
    func bottomSheetPresentationController(_ presentationController: BottomSheetPresentationController, willDismissPresentedViewController presentedViewController: UIViewController, by action: BottomSheetDismissAction)
    func bottomSheetPresentationController(_ presentationController: BottomSheetPresentationController, didDismissPresentedViewController presentedViewController: UIViewController, by action: BottomSheetDismissAction)
    func bottomSheetPresentationControllerCompactHeight(_ presentationController: BottomSheetPresentationController) -> CGFloat
}

class BottomSheetPresentationController: UIPresentationController {
    // MARK: - Internal properties

    var state: BottomSheetState {
        get { return stateController.state }
        set { updateState(newValue) }
    }

    weak var presentationControllerDelegate: BottomSheetPresentationControllerDelegate?

    private let interactionController: BottomSheetInteractionController

    private(set) lazy var dimView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var constraint: NSLayoutConstraint? // Constraint is used to set the y position of the bottom sheet
    private var gestureController: BottomSheetGestureController?
    private let springAnimator = SpringAnimator(dampingRatio: 0.78, frequencyResponse: 0.5)
    private lazy var stateController = BottomSheetStateController(view: containerView)

    private var hasReachExpandedPosition = false
    private var dismissAction: BottomSheetDismissAction = .none

    private var currentPosition: CGPoint {
        guard let constraint = constraint else { return .zero }
        return CGPoint(x: 0, y: constraint.constant)
    }

    override var presentationStyle: UIModalPresentationStyle {
        return .overCurrentContext
    }

    var compactHeight: CGFloat = 0

    // MARK: - Init

    init(presentedViewController: UIViewController, presenting: UIViewController?, interactionController: BottomSheetInteractionController) {
        self.interactionController = interactionController
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        interactionController.delegate = self

        addObserverForKeyboardNotification(named: UIResponder.keyboardWillShowNotification)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func addObserverForKeyboardNotification(named name: NSNotification.Name) {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustScrollViewForKeyboard(_:)), name: name, object: nil)
    }

    @objc private func adjustScrollViewForKeyboard(_ notification: Notification) {
        guard let keyboardInfo = KeyboardNotificationInfo(notification) else { return }
        guard let containerView = containerView else { return }
        let keyboardHeight = keyboardInfo.keyboardFrameEndIntersectHeight(inView: containerView)

        if keyboardInfo.action == .willShow {
            if let aCompactHeight = presentationControllerDelegate?.bottomSheetPresentationControllerCompactHeight(self), aCompactHeight != -999 {
                self.compactHeight =  containerView.bounds.height - aCompactHeight - keyboardHeight
            } else {
                self.compactHeight =  containerView.bounds.height * 0.50 - keyboardHeight
            }

            let targetPosition = stateController.targetPosition(for: .compact, compactHeight: self.compactHeight)
            self.animate(to: targetPosition)
        }
    }

    // MARK: - Overrides

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView, let bottomSheet = presentedViewController as? BottomSheet else { return }
        setupDimView(dimView, inContainerView: containerView)
        setupPresentedView(bottomSheet.view, inContainerView: containerView)
        // Setup controller
        stateController.frame = containerView.bounds
        gestureController = BottomSheetGestureController(bottomSheet: bottomSheet, containerView: containerView)
        interactionController.setup(with: constraint)
        interactionController.stateController = stateController
        // Setup animations
        springAnimator.addAnimation { [weak self] position in
            self?.constraint?.constant = position.y
        }
        // Animate dim view alpha in sync with transition animation
        interactionController.animate { [weak self] position in
            self?.dimView.alpha = self?.alphaValue(for: position, compactHeight: self?.compactHeight ?? 0) ?? 0
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        // If completed is false, the transition was cancelled by user interaction
        guard completed else { return }
        gestureController?.delegate = self
    }

    override func dismissalTransitionWillBegin() {
        springAnimator.stopAnimation(true)
        // Make sure initial transition velocity is the same the current velocity of the bottom sheet
        interactionController.initialTransitionVelocity = -(gestureController?.velocity ?? .zero)
        presentationControllerDelegate?.bottomSheetPresentationController(self, willDismissPresentedViewController: presentedViewController, by: dismissAction)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // Completed should always be true at this point of development
        guard !completed else {
            presentationControllerDelegate?.bottomSheetPresentationController(self, didDismissPresentedViewController: presentedViewController, by: dismissAction)
            return
        }
        gestureController?.delegate = self
    }
}

private extension BottomSheetPresentationController {
    func setupDimView(_ dimView: UIView, inContainerView containerView: UIView) {
        containerView.addSubview(dimView)
        dimView.fillInSuperview()
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    func setupPresentedView(_ presentedView: UIView, inContainerView containerView: UIView) {
        containerView.addSubview(presentedView)
        presentedView.translatesAutoresizingMaskIntoConstraints = false
        if let aCompactHeight = presentationControllerDelegate?.bottomSheetPresentationControllerCompactHeight(self), aCompactHeight != -999 {
            self.compactHeight =  containerView.bounds.height - aCompactHeight
        } else {
            self.compactHeight =  containerView.bounds.height * 0.50
        }
        let constraint = presentedView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: containerView.bounds.height)
        NSLayoutConstraint.activate([
            constraint,
            presentedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            presentedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            presentedView.heightAnchor.constraint(greaterThanOrEqualToConstant: compactHeight),
            presentedView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor),
        ])
        self.constraint = constraint
    }

    func alphaValue(for position: CGPoint, compactHeight: CGFloat) -> CGFloat {
        guard let containerView = containerView else { return 0 }
        return (containerView.bounds.height - position.y) / compactHeight
    }

    func updateState(_ state: BottomSheetState) {
        guard state != stateController.state else { return }
        stateController.state = state
        animate(to: stateController.targetPosition(for: stateController.state, compactHeight: self.compactHeight) )
    }

    @objc func handleTap() {
        guard stateController.state != .dismissed else { return }

        if presentationControllerDelegate?.bottomSheetPresentationControllerShouldDismiss(self) ?? true {
            stateController.state = .dismissed
            gestureController?.velocity = .zero
            dismissAction = .tap
            presentedViewController.dismiss(animated: true)
        } else {
            presentationControllerDelegate?.bottomSheetPresentationControllerDidCancelDismiss(self)
        }
    }

    func animate(to position: CGPoint, initialVelocity: CGPoint = .zero) {
        switch stateController.state {
        case .dismissed:
            presentedViewController.dismiss(animated: true)
        default:
            springAnimator.fromPosition = currentPosition
            springAnimator.toPosition = position
            springAnimator.initialVelocity = initialVelocity
            springAnimator.startAnimation()
        }
    }
}

extension BottomSheetPresentationController: BottomSheetGestureControllerDelegate {
    // This method expects to return the current position of the bottom sheet
    func bottomSheetGestureControllerDidBeginGesture(_ controller: BottomSheetGestureController) -> CGPoint {
        guard let constraint = constraint, constraint.constant > stateController.expandedPosition.y else {
            hasReachExpandedPosition = true
            return currentPosition
        }
        springAnimator.pauseAnimation()
        return currentPosition
    }
    // Position is the position of the bottom sheet in the container view
    func bottomSheetGestureControllerDidChangeGesture(_ controller: BottomSheetGestureController) {
        if controller.position.y <= stateController.expandedPosition.y {
            guard !hasReachExpandedPosition else { return }
            hasReachExpandedPosition = true
            animate(to: stateController.expandedPosition, initialVelocity: -controller.velocity)
            return
        }

        let newPosition = stateAdjustedPosition(forGestureController: controller)

        hasReachExpandedPosition = false
        dimView.alpha = alphaValue(for: newPosition, compactHeight: self.compactHeight)
        constraint?.constant = newPosition.y
    }

    func bottomSheetGestureControllerDidEndGesture(_ controller: BottomSheetGestureController) {
        stateController.updateState(withTranslation: controller.translation)
        guard !hasReachExpandedPosition else { return }

        if stateController.state == .dismissed {
            presentedView?.endEditing(true)

            if presentationControllerDelegate?.bottomSheetPresentationControllerShouldDismiss(self) ?? true {
                dismissAction = .drag
            } else {
                stateController.state = .compact
                presentationControllerDelegate?.bottomSheetPresentationControllerDidCancelDismiss(self)
            }
        }

        animate(to: stateController.targetPosition(for: stateController.state, compactHeight: self.compactHeight), initialVelocity: -controller.velocity)
    }

    func stateAdjustedPosition(forGestureController controller: BottomSheetGestureController) -> CGPoint {
        let canDismiss = presentationControllerDelegate?.bottomSheetPresentationControllerShouldDismiss(self) ?? true
        let thresholdPoint = stateController.frame.height - self.compactHeight

        let ycomponent: CGFloat
        if !canDismiss, controller.position.y >= thresholdPoint {
            ycomponent = thresholdPoint + (controller.position.y - thresholdPoint) * 0.33
        } else {
            ycomponent = controller.position.y
        }

        return CGPoint(x: controller.position.x, y: ycomponent)
    }
}

extension BottomSheetPresentationController: BottomSheetInteractionControllerDelegate {
    func bottomSheetInteractionControllerCompactHeight(_ bottomSheetInteractionController: BottomSheetInteractionController) -> CGFloat {
        return self.compactHeight
    }

    func bottomSheetInteractionControllerWillCancelPresentationTransition(_ interactionController: BottomSheetInteractionController) {
        presentationControllerDelegate?.bottomSheetPresentationController(self, willDismissPresentedViewController: presentedViewController, by: .drag)
    }
}
