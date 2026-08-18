import UIKit

@MainActor
final class PinTrayCardView: UIView {
    let surface = UIView()

    weak var reporting: PinTrayCardReporting?

    init(nestedIn displayCornerRadius: CGFloat) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = displayCornerRadius
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(drag))
        pan.delegate = self
        addGestureRecognizer(pan)

        surface.translatesAutoresizingMaskIntoConstraints = false
        surface.backgroundColor = .primaryBackground
        surface.layer.cornerRadius = trayTopRadius
        surface.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        surface.layer.cornerCurve = .continuous
        surface.clipsToBounds = true
        addSubview(surface)

        NSLayoutConstraint.activate([
            surface.leadingAnchor.constraint(equalTo: leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: trailingAnchor),
            surface.topAnchor.constraint(equalTo: topAnchor),
            surface.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayCardView is made in code") }

    func show(_ geometry: PinTrayGeometry) {
        layer.cornerRadius = geometry.bottomCornerRadius
    }
}

extension PinTrayCardView {
    @objc private func drag(_ gesture: UIPanGestureRecognizer) {
        let travelled = gesture.translation(in: superview).y
        switch gesture.state {
        case .began:
            reporting?.cardWasTouched()
            gesture.setTranslation(
                CGPoint(x: 0, y: reporting?.pulledSoFar ?? 0),
                in: superview
            )
        case .changed:
            reporting?.cardWasDragged(to: travelled)
        case .ended, .cancelled:
            reporting?.cardWasReleased(velocity: gesture.velocity(in: superview).y)
        default:
            break
        }
    }
}

extension PinTrayCardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let candidate = view, candidate !== self {
            if let scroll = candidate as? UIScrollView, scroll.isScrollEnabled { return false }
            view = candidate.superview
        }
        return true
    }
}
