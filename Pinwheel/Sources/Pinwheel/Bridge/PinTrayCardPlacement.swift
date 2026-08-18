import UIKit

@MainActor
final class PinTrayCardPlacement {
    private let card: PinTrayCardView
    private unowned let parent: UIView
    private let height: NSLayoutConstraint
    private let offset: NSLayoutConstraint
    private let lifted: NSLayoutConstraint
    private var motion: UIViewPropertyAnimator?

    init(card: PinTrayCardView, in parent: UIView) {
        self.card = card
        self.parent = parent

        let height = card.heightAnchor.constraint(equalToConstant: 0)
        height.priority = .defaultHigh
        self.height = height

        let offset = card.bottomAnchor.constraint(
            equalTo: parent.keyboardLayoutGuide.topAnchor,
            constant: -trayBottomMargin
        )
        let lifted = card.bottomAnchor.constraint(
            equalTo: parent.keyboardLayoutGuide.topAnchor,
            constant: -trayKeyboardMargin
        )
        offset.priority = UILayoutPriority(999)
        lifted.priority = UILayoutPriority(999)
        self.offset = offset
        self.lifted = lifted

        parent.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: trayMargin),
            card.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -trayMargin),
            card.topAnchor.constraint(
                greaterThanOrEqualTo: parent.safeAreaLayoutGuide.topAnchor,
                constant: trayMargin
            ),
            height,
        ])
    }

    /// A keyboard layout guide only tracks once its view belongs to a scene. Armed any earlier the swap
    /// never registers, the card's bottom is pinned to nothing, and it floats to the top of the screen.
    func followTheKeyboard() {
        parent.keyboardLayoutGuide.usesBottomSafeArea = false
        parent.keyboardLayoutGuide.setConstraints([offset], activeWhenNearEdge: .bottom)
        parent.keyboardLayoutGuide.setConstraints([lifted], activeWhenAwayFrom: .bottom)
    }

    var travelled: CGFloat { card.transform.ty }

    var isTravelling: Bool { motion?.isRunning == true }

    func stopTravelling() {
        motion?.stopAnimation(true)
        motion = nil
    }

    func write(_ geometry: PinTrayGeometry) {
        card.show(geometry)
        height.constant = geometry.height
        offset.constant = -geometry.clearanceAboveGuide
    }

    func place(
        _ geometry: PinTrayGeometry,
        alongside: @escaping () -> Void,
        matching timing: PinTrayMachine.KeyboardTiming,
        then finish: @escaping () -> Void
    ) {
        UIView.animate(
            withDuration: timing.duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: UInt(timing.curve) << 16),
            animations: {
                self.draw(geometry)
                alongside()
            },
            completion: { _ in finish() }
        )
    }

    func place(
        _ geometry: PinTrayGeometry,
        alongside: @escaping () -> Void,
        animated: Bool,
        bounce: CGFloat = trayResizeBounce,
        startingAt initialVelocity: CGFloat = 0,
        then finish: @escaping () -> Void = {}
    ) {
        let draw = {
            self.draw(geometry)
            alongside()
        }
        stopTravelling()
        guard animated else { draw(); return finish() }
        let animator = UIViewPropertyAnimator(
            duration: trayResizeDuration,
            timingParameters: UISpringTimingParameters(
                duration: trayResizeDuration,
                bounce: bounce,
                initialVelocity: CGVector(dx: 0, dy: initialVelocity)
            )
        )
        animator.addAnimations(draw)
        animator.addCompletion { position in
            guard position == .end else { return }
            finish()
        }
        motion = animator
        animator.startAnimation()
    }

    private func draw(_ geometry: PinTrayGeometry) {
        write(geometry)
        card.transform = CGAffineTransform(translationX: 0, y: geometry.translation)
        card.superview?.layoutIfNeeded()
    }
}
