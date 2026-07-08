import UIKit
import Pinwheel

class UIKitPinNumbersDemo: UIKitPinView {
    private let spacings: [(String, CGFloat)] = [
        ("spacingXXS", .spacingXXS),
        ("spacingXS", .spacingXS),
        ("spacingXM", .spacingXM),
        ("spacingS", .spacingS),
        ("spacingM", .spacingM),
        ("spacingL", .spacingL),
        ("spacingXL", .spacingXL),
        ("spacingXXL", .spacingXXL)
    ]

    private let radii: [(String, CGFloat)] = [
        ("radiusM", .radiusM),
        ("radiusL", .radiusL)
    ]

    private let concentricOuter: CGFloat = .radiusL
    private let concentricInsets: [CGFloat] = [.spacingXS, .spacingM, .spacingL]

    override func setup() {
        let stackView = UIStackView(withAutoLayout: true)
        stackView.axis = .vertical
        stackView.spacing = .spacingXXL

        stackView.addArrangedSubview(header("Spacing"))
        for (title, spacing) in spacings {
            stackView.addArrangedSubview(spacingBar(title: title, inset: spacing))
        }
        stackView.addArrangedSubview(header("Radius"))
        for (title, radius) in radii {
            stackView.addArrangedSubview(radiusBar(title: title, radius: radius))
        }
        stackView.addArrangedSubview(header("Concentric radius"))
        for inset in concentricInsets {
            stackView.addArrangedSubview(concentricExample(inset: inset))
        }
        stackView.addArrangedSubview(concentricStack())

        // Pinned directly to the view (not wrapped in a UIScrollView): a scroll view lays its content
        // out lazily/deferred, so an off-screen capture host sometimes reads zero-frame labels and falls
        // back to a flat image. A pinned stack always lays out, so every row captures.
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: .spacingXXL),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingL)
        ])
    }

    private func header(_ text: String) -> UIKitPinLabel {
        let label = UIKitPinLabel(font: .title)
        label.text = text
        return label
    }

    // The colored bar is inset horizontally by the spacing value, so the gap on each side is the token.
    private func spacingBar(title: String, inset: CGFloat) -> UIView {
        let container = UIView(withAutoLayout: true)
        let label = makeBarLabel(text: "\(title) \(Int(inset))")
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: .spacingS),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -.spacingS)
        ])
        return container
    }

    private func radiusBar(title: String, radius: CGFloat) -> UIView {
        let label = makeBarLabel(text: "\(title) \(Int(radius))")
        label.layer.cornerRadius = radius
        label.layer.masksToBounds = true
        label.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return label
    }

    private func makeBarLabel(text: String) -> UIKitPinLabel {
        let label = UIKitPinLabel(font: .body)
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = .tertiaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    // The inner layer's radius is the outer radius minus its inset, so the corners stay concentric.
    private func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }

    private func concentricExample(inset: CGFloat) -> UIView {
        let inner = concentricRadius(outer: concentricOuter, inset: inset)
        let outerView = roundedView(color: .tertiaryText, radius: concentricOuter)
        outerView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        let innerView = roundedView(color: .primaryBackground, radius: inner)
        embed(innerView, in: outerView, inset: inset)

        let caption = captionLabel("outer \(Int(concentricOuter)) · inset \(Int(inset)) → inner \(Int(inner))")
        return column([caption, outerView])
    }

    private func concentricStack() -> UIView {
        let gap: CGFloat = .spacingS
        let middle = concentricRadius(outer: concentricOuter, inset: gap)
        let inner = concentricRadius(outer: middle, inset: gap)

        let outerView = roundedView(color: .tertiaryText, radius: concentricOuter)
        outerView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        let middleView = roundedView(color: .primaryBackground, radius: middle)
        embed(middleView, in: outerView, inset: gap)
        let innerView = roundedView(color: .tertiaryText, radius: inner)
        embed(innerView, in: middleView, inset: gap)

        let caption = captionLabel("3 layers · gap \(Int(gap)) → \(Int(concentricOuter)) / \(Int(middle)) / \(Int(inner))")
        return column([caption, outerView])
    }

    private func roundedView(color: UIColor, radius: CGFloat) -> UIView {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = color
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true
        return view
    }

    private func embed(_ inner: UIView, in outer: UIView, inset: CGFloat) {
        outer.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: inset),
            inner.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -inset),
            inner.topAnchor.constraint(equalTo: outer.topAnchor, constant: inset),
            inner.bottomAnchor.constraint(equalTo: outer.bottomAnchor, constant: -inset)
        ])
    }

    private func captionLabel(_ text: String) -> UIKitPinLabel {
        let label = UIKitPinLabel(font: .caption, textColor: .secondaryText)
        label.text = text
        return label
    }

    private func column(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = .spacingS
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
}
