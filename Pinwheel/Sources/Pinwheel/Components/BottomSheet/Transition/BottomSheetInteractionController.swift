import UIKit

protocol BottomSheetInteractionControllerDelegate: AnyObject {
    func bottomSheetInteractionControllerWillCancelPresentationTransition(_ interactionController: BottomSheetInteractionController)
    func bottomSheetInteractionControllerHeight(_ bottomSheetInteractionController: BottomSheetInteractionController) -> BottomSheetHeight
}

/**
 This object is controlling the animation of the transition using the animator object

 This object should be the delegate of a gesture controller during the transition in order to interact with the transition.
 The presentation controller owns the gesture controller and have to set the delegate.
 The constraint should also be provided by the presentation controller
**/
class BottomSheetInteractionController: NSObject, UIViewControllerInteractiveTransitioning {

    let animationController: BottomSheetAnimationController
    var initialTransitionVelocity: CGPoint = .zero
    var stateController: BottomSheetStateController?

    weak var delegate: BottomSheetInteractionControllerDelegate?

    private var constraint: NSLayoutConstraint?
    private var transitionContext: UIViewControllerContextTransitioning?

    private var hasReachExpandedPosition = false
    private var currentPosition: CGPoint {
        guard let constraint = constraint else { return .zero }
        return CGPoint(x: 0, y: constraint.constant)
    }

    init(animationController: BottomSheetAnimationController) {
        self.animationController = animationController
    }

    func setup(with constraint: NSLayoutConstraint?) {
        self.constraint = constraint
        animationController.setup(with: constraint)
    }

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        // Keep track of context for any future transition related actions
        self.transitionContext = transitionContext
        // Start transition animation
        if let state = stateController {
            let defaultCompactHeight: Double = transitionContext.containerView.frame.height * 0.50
            let height = delegate?.bottomSheetInteractionControllerHeight(self) ?? .compact(defaultCompactHeight)
            animationController.targetPosition = state.targetPosition(for: state.state, height: height)
        }
        animationController.initialVelocity = initialTransitionVelocity
        animationController.animateTransition(using: transitionContext)
    }

    func animate(alongsideTransition animation: @escaping (CGPoint) -> Void) {
        animationController.addAnimation(animation)
    }
}
