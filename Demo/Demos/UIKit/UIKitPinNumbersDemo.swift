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

        let scrollView = UIScrollView(withAutoLayout: true)
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.fillInSuperview()

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: .spacingXXL),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -.spacingL),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: .spacingL),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -.spacingL)
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
}
