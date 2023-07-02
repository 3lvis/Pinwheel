import UIKit

class BottomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    var presentationController: BottomSheetPresentationController?
    weak var presentationControllerDelegate: BottomSheetPresentationControllerDelegate?

    private let interactionController: BottomSheetInteractionController
    private let animationController: BottomSheetAnimationController

    private(set) lazy var dimView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var compactHeight: CGFloat {
        didSet {
            presentationController?.compactHeight = compactHeight
        }
    }

    init(compactHeight: CGFloat) {
        self.compactHeight = compactHeight
        animationController = BottomSheetAnimationController()
        interactionController = BottomSheetInteractionController(animationController: animationController)
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        presentationController = BottomSheetPresentationController(presentedViewController: presented,
                                                                   presenting: presenting,
                                                                   compactHeight: compactHeight,
                                                                   interactionController: interactionController,
                                                                   dimView: dimView)
        presentationController?.presentationControllerDelegate = presentationControllerDelegate
        return presentationController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationController
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
