import UIKit

extension UIStackView {
    public convenience init(
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat? = nil,
        alignment: UIStackView.Alignment? = nil,
        distribution: UIStackView.Distribution? = nil
    ) {
        self.init()

        self.translatesAutoresizingMaskIntoConstraints = false

        self.axis = axis

        if let spacing = spacing {
            self.spacing = spacing
        }

        if let alignment = alignment {
            self.alignment = alignment
        }

        if let distribution = distribution {
            self.distribution = distribution
        }
    }

    public func removeArrangedSubviews() {
        for oldSubview in arrangedSubviews {
            removeArrangedSubview(oldSubview)
            oldSubview.removeFromSuperview()
        }
    }

    public func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach(addArrangedSubview)
    }
}
