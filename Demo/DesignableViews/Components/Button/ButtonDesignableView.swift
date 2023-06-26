import UIKit
import Designable

public class ButtonDesignableView: UIView {
    let states: [UIControl.State] = [.normal, .disabled]

    // Relevant Styles, States and Sizes to show for the designable view
    let styles: [(style: Button.Style, title: String)] = [
        (style: .default, title: "Default"),
        (style: .flat, title: "Flat"),
        (style: .link, title: "Link"),
        (style: .callToAction, title: "Call to Action"),
        (style: .destructive, title: "Destructive"),
        (style: .destructiveFlat, title: "Destructive Flat"),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    private func setup() {
        let scrollView = UIScrollView(withAutoLayout: true)
        scrollView.contentInset = UIEdgeInsets(vertical: .spacingM, horizontal: .spacingL)

        let verticalStack = UIStackView(axis: .vertical, spacing: .spacingM, withAutoLayout: true)

        styles.forEach { styleTuple in
            let buttonStyleStack = UIStackView(axis: .vertical, spacing: .spacingS, withAutoLayout: true)

            let titleLabel = Label(style: .bodyStrong, withAutoLayout: true)
            titleLabel.text = styleTuple.title
            buttonStyleStack.addArrangedSubview(titleLabel)

            let stateStack = UIStackView(withAutoLayout: true)
            stateStack.axis = .horizontal
            stateStack.spacing = .spacingS
            stateStack.distribution = .fillEqually

            states.forEach { state in
                let title = title(state: state)

                let button = Button(style: styleTuple.style, withAutoLayout: true)
                button.setTitle(title, for: state)
                button.isEnabled = state != .disabled

                stateStack.addArrangedSubview(button)
            }

            buttonStyleStack.addArrangedSubview(stateStack)

            verticalStack.addArrangedSubview(buttonStyleStack)
        }

        scrollView.addSubview(verticalStack)
        addSubview(scrollView)

        scrollView.fillInSuperview()
        verticalStack.fillInSuperview()
        NSLayoutConstraint.activate([
            verticalStack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0, constant: -.spacingL * 2)
        ])
    }

    // MARK: - Private methods

    private func title(state: UIControl.State) -> String {
        stateName(state: state)
    }

    private func stateName(state: UIControl.State) -> String {
        switch state {
        case .normal: return "Normal"
        case .disabled: return "Disabled"
        case .highlighted: return "Highlghted"
        default: return "?"
        }
    }
}
