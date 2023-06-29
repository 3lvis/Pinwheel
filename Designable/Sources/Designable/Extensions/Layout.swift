import UIKit

public extension UIView {
    func fillInSuperview(margin: CGFloat) {
        fillInSuperview(insets: UIEdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin))
    }

    func fillInSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.trailing),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func fillInSafeArea(margin: CGFloat) {
        fillInSafeArea(insets: UIEdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin))
    }

    func fillInSafeArea(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -insets.trailing),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func anchorToTopSafeArea(margin: CGFloat) {
        anchorToTopSafeArea(insets: UIEdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin))
    }

    func anchorToTopSafeArea(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -insets.trailing),
        ])
    }

    func anchorToBottomSafeArea(margin: CGFloat) {
        anchorToBottomSafeArea(insets: UIEdgeInsets(top: margin, leading: margin, bottom: margin, trailing: margin))
    }

    func anchorToBottomSafeArea(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: insets.leading),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -insets.trailing),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
