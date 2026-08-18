import SwiftUI
import UIKit

@MainActor
final class PinTrayAccessoryView: UIView {
    private enum Standing {
        case nothing
        case floating(PinTrayLeafView)
        case commitButton(PinTrayLeafView)

        var view: PinTrayLeafView? {
            switch self {
            case .nothing: nil
            case .floating(let view), .commitButton(let view): view
            }
        }

        var isCommitButton: Bool {
            if case .commitButton = self { return true }
            return false
        }
    }

    private var standing: Standing = .nothing
    private unowned let parent: UIViewController

    init(in parent: UIViewController) {
        self.parent = parent
        super.init(frame: .zero)
        isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayAccessoryView is made in code") }

    var height: CGFloat { height(fitting: bounds.width) }

    func height(fitting width: CGFloat) -> CGFloat {
        switch standing {
        case .nothing: 0
        case .floating(let view), .commitButton(let view): view.height(fitting: width)
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    func show(_ accessory: PinTrayAccessory, replacing: Bool, over duration: TimeInterval) {
        let leaving = standing
        guard let leaf = accessory.leaf else {
            standing = .nothing
            fade(leaving.view, to: 0, animated: replacing, over: duration) { $0.detach() }
            return
        }

        let arriving = PinTrayLeafView(showing: leaf, in: parent)
        arriving.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arriving)
        NSLayoutConstraint.activate([
            arriving.leadingAnchor.constraint(equalTo: leadingAnchor),
            arriving.trailingAnchor.constraint(equalTo: trailingAnchor),
            arriving.topAnchor.constraint(equalTo: topAnchor),
            arriving.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let holds = replacing && leaving.isCommitButton && accessory.isCommitButton
        arriving.alpha = holds || !replacing ? 1 : 0
        if holds, let left = leaving.view { bringSubviewToFront(left) }

        standing = accessory.isCommitButton ? .commitButton(arriving) : .floating(arriving)
        invalidateIntrinsicContentSize()

        guard replacing else {
            leaving.view?.detach()
            leaving.view?.removeFromSuperview()
            return
        }
        UIView.animate(withDuration: duration) {
            arriving.alpha = 1
            leaving.view?.alpha = 0
        } completion: { _ in
            leaving.view?.detach()
            leaving.view?.removeFromSuperview()
        }
    }

    private func fade(
        _ view: PinTrayLeafView?,
        to alpha: CGFloat,
        animated: Bool,
        over duration: TimeInterval,
        then finish: @escaping (PinTrayLeafView) -> Void
    ) {
        guard let view else { return }
        guard animated else { finish(view); view.removeFromSuperview(); return }
        UIView.animate(withDuration: duration) {
            view.alpha = alpha
        } completion: { _ in
            finish(view)
            view.removeFromSuperview()
        }
    }

    func detach() {
        standing.view?.detach()
        standing = .nothing
    }
}
