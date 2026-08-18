import UIKit

protocol CornerAnchoringViewDelegate: AnyObject {
    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView)
    func cornerAnchoringViewDidSelectCloseButton(_ cornerAnchoringView: CornerAnchoringView)
}

final class CornerAnchoringView: UIView {
    weak var delegate: CornerAnchoringViewDelegate?
    let buttonSize = CGFloat.minimumControlHeight

    private let buttonsContent = UIView(withAutoLayout: true)

    private lazy var buttonsView: UIView = {
        let views = UIView()
        views.translatesAutoresizingMaskIntoConstraints = false
        views.addSubview(buttonsContent)
        NSLayoutConstraint.activate([
            buttonsContent.leadingAnchor.constraint(equalTo: views.leadingAnchor),
            buttonsContent.trailingAnchor.constraint(equalTo: views.trailingAnchor),
            buttonsContent.topAnchor.constraint(equalTo: views.topAnchor),
            buttonsContent.bottomAnchor.constraint(equalTo: views.bottomAnchor),
            buttonsContent.widthAnchor.constraint(equalToConstant: buttonSize),
            buttonsContent.heightAnchor.constraint(equalToConstant: buttonSize * 2 + .spacing3),
        ])
        return views
    }()

    /// The caller parents the hosting controller: the theme rides a trait, which only reaches a view
    /// whose controller is in the hierarchy.
    func setButtonsContent(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        buttonsContent.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: buttonsContent.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: buttonsContent.trailingAnchor),
            view.topAnchor.constraint(equalTo: buttonsContent.topAnchor),
            view.bottomAnchor.constraint(equalTo: buttonsContent.bottomAnchor),
        ])
    }

    private var anchorAreaViews = [UIView]()
    private let panRecognizer = UIPanGestureRecognizer()
    private var initialOffset: CGPoint = .zero

    private var anchorPositions: [CGPoint] {
        return anchorAreaViews.map { $0.center }
    }

    public var itemsCount: Int = 0 {
        didSet {
            onItemsCountChange?(itemsCount)
        }
    }

    var onItemsCountChange: ((Int) -> Void)?

    func setControlsHidden(_ hidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        let apply = {
            self.buttonsView.alpha = hidden ? 0 : 1
            self.buttonsView.transform = hidden ? CGAffineTransform(scaleX: 0.6, y: 0.6) : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: apply) { _ in
                completion?()
            }
        } else {
            apply()
            completion?()
        }
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private var bottomLeftViewSafeBottomConstraint: NSLayoutConstraint?
    private var bottomLeftViewKeyboardBottomConstraint: NSLayoutConstraint?

    private var bottomRightViewSafeBottomConstraint: NSLayoutConstraint?
    private var bottomRightViewKeyboardBottomConstraint: NSLayoutConstraint?

    func setup() {
        let topLeftView = addAnchorAreaView()
        topLeftView.accessibilityIdentifier = "CornerAnchoringView-topLeftView"

        let topRightView = addAnchorAreaView()
        topRightView.accessibilityIdentifier = "CornerAnchoringView-topRightView"

        let bottomLeftView = addAnchorAreaView()
        bottomLeftView.accessibilityIdentifier = "CornerAnchoringView-bottomLeftView"

        let bottomRightView = addAnchorAreaView()
        bottomRightView.accessibilityIdentifier = "CornerAnchoringView-bottomRightView"

        addSubview(buttonsView)

        let buttonHeight = buttonSize * 2 + .spacing2
        let buttonWidth = buttonSize

        NSLayoutConstraint.activate([
            topLeftView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacing4 + buttonWidth / 2),
            topLeftView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .spacing4 + buttonHeight / 2),

            topRightView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacing4 - buttonWidth / 2),
            topRightView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .spacing4 + buttonHeight / 2),

            bottomLeftView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacing4 + buttonWidth / 2),

            bottomRightView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacing4 - buttonWidth / 2)
        ])

        bottomLeftViewKeyboardBottomConstraint = bottomLeftView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -.spacing4 - buttonHeight / 2)
        bottomLeftViewKeyboardBottomConstraint?.isActive = false
        bottomLeftViewSafeBottomConstraint = bottomLeftView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacing4 - buttonHeight / 2)
        bottomLeftViewSafeBottomConstraint?.isActive = true

        bottomRightViewKeyboardBottomConstraint = bottomRightView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -.spacing4 - buttonHeight / 2)
        bottomRightViewKeyboardBottomConstraint?.isActive = false
        bottomRightViewSafeBottomConstraint = bottomRightView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacing4 - buttonHeight / 2)
        bottomRightViewSafeBottomConstraint?.isActive = true

        panRecognizer.addTarget(self, action: #selector(anchoredViewPanned(recognizer:)))
        // Don't hold the button's touch-up while the pan recognizer evaluates a
        // possible drag, so a tap on close/settings fires immediately.
        panRecognizer.delaysTouchesEnded = false
        buttonsView.addGestureRecognizer(panRecognizer)

        setupKeyboardNotifications()
    }

    /// The FAB lives in an overlay window above the app, so nothing else moves it
    /// clear of the keyboard. These notifications swap each bottom corner between
    /// its safe-area and `keyboardLayoutGuide.topAnchor` constraints so the
    /// buttons stay tappable on keyboard-bearing screens.
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
              let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
            return
        }

        let animationCurveRaw = animationCurveRawNSN.uintValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)

        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0, options: animationCurve, animations: {
            self.bottomLeftViewSafeBottomConstraint?.isActive = false
            self.bottomLeftViewKeyboardBottomConstraint?.isActive = true

            self.bottomRightViewSafeBottomConstraint?.isActive = false
            self.bottomRightViewKeyboardBottomConstraint?.isActive = true
            self.layoutIfNeeded()
        }, completion: nil)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
              let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else {
            return
        }

        let animationCurveRaw = animationCurveRawNSN.uintValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw << 16)

        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0, options: animationCurve, animations: {
            self.bottomLeftViewKeyboardBottomConstraint?.isActive = false
            self.bottomLeftViewSafeBottomConstraint?.isActive = true

            self.bottomRightViewKeyboardBottomConstraint?.isActive = false
            self.bottomRightViewSafeBottomConstraint?.isActive = true
            self.layoutIfNeeded()
        }, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func layoutSubviews() {
        super.layoutSubviews()

        if let index = PinwheelStateStore.floatingControlsCorner, let position = anchorPositions[safe: index] {
            buttonsView.center = position
        } else {
            buttonsView.center = anchorPositions.last ?? .zero
        }
    }

    private func addAnchorAreaView() -> UIView {
        let view = UIView(withAutoLayout: true)
        addSubview(view)
        anchorAreaViews.append(view)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 0),
            view.heightAnchor.constraint(equalToConstant: 0)
        ])
        view.isUserInteractionEnabled = false
        return view
    }

    @objc private func anchoredViewPanned(recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            initialOffset = CGPoint(x: touchPoint.x - buttonsView.center.x, y: touchPoint.y - buttonsView.center.y)
        case .changed:
            buttonsView.center = CGPoint(x: touchPoint.x - initialOffset.x, y: touchPoint.y - initialOffset.y)
        case .ended, .cancelled:
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
            let velocity = recognizer.velocity(in: self)
            let projectedPosition = CGPoint(
                x: buttonsView.center.x + project(initialVelocity: velocity.x, decelerationRate: decelerationRate),
                y: buttonsView.center.y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate)
            )
            let (index, nearestCornerPosition) = nearestCorner(to: projectedPosition)
            let relativeInitialVelocity = CGVector(
                dx: relativeVelocity(forVelocity: velocity.x, from: buttonsView.center.x, to: nearestCornerPosition.x),
                dy: relativeVelocity(forVelocity: velocity.y, from: buttonsView.center.y, to: nearestCornerPosition.y)
            )
            PinwheelStateStore.floatingControlsCorner = index
            let timingParameters = UISpringTimingParameters(damping: 1, response: 0.4, initialVelocity: relativeInitialVelocity)
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
            animator.addAnimations {
                self.buttonsView.center = nearestCornerPosition
            }
            animator.startAnimation()
        default: break
        }
    }

    /// Distance traveled after decelerating to zero velocity at a constant rate.
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
    }

    private func nearestCorner(to point: CGPoint) -> (Int, CGPoint) {
        var minDistance = CGFloat.greatestFiniteMagnitude
        var closestPosition = CGPoint.zero
        var arrayIndex = 0
        for (index, position) in anchorPositions.enumerated() {
            let distance = point.distance(to: position)
            if distance < minDistance {
                closestPosition = position
                arrayIndex = index
                minDistance = distance
            }
        }
        return (arrayIndex, closestPosition)
    }

    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat {
        guard currentValue - targetValue != 0 else { return 0 }
        return velocity / (targetValue - currentValue)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: {
            !$0.isHidden && $0.point(inside: self.convert(point, to: $0), with: event)
        })
    }


}

extension UISpringTimingParameters {

    /// `damping` must be between 0 and 1.
    convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }

}

extension CGPoint {

    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - self.x, 2) + pow(point.y - self.y, 2))
    }

}
