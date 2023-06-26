import UIKit

public class Button: UIButton {
    // MARK: - Internal properties

    private let cornerRadius: CGFloat = 8.0
    private var titleHeight: CGFloat?
    private var titleWidth: CGFloat?

    // MARK: - External properties

    public var style: Style {
        didSet { setup() }
    }

    // MARK: - Initializers

    public init(style: Style, withAutoLayout: Bool = false) {
        self.style = style
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !withAutoLayout
        setup()
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(style: .default)
    }

    // MARK: - Overrides

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = style.backgroundColor(forState: state)
            layer.borderColor = style.borderColor(forState: state)
        }
    }

    public override var isEnabled: Bool {
        didSet {
            backgroundColor = style.backgroundColor(forState: state)
            layer.borderColor = style.borderColor(forState: state)
        }
    }

    public override var intrinsicContentSize: CGSize {
        guard let titleWidth = titleWidth, let titleHeight = titleHeight else {
            return CGSize.zero
        }
        let paddings = style.paddings
        let imageSize = imageView?.image?.size ?? .zero

        return CGSize(
            width: titleWidth + imageSize.width + style.margins.left + style.margins.right,
            height: titleHeight + style.margins.top + style.margins.bottom + paddings.top + paddings.bottom
        )
    }

    public override func setTitle(_ title: String?, for state: UIControl.State) {
        guard let title = title else {
            return
        }

        titleHeight = title.height(withConstrainedWidth: bounds.width, font: .bodyStrong)
        titleWidth = title.width(withConstrainedHeight: bounds.height, font: .bodyStrong)

        if style == .link {
            setAsLink(title: title)
        } else {
            super.setTitle(title, for: state)
        }

        if state == .normal {
            accessibilityLabel = title
        }
    }

    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        assertionFailure("The title color cannot be changed outside the class")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Border color is set in a lifecycle method to ensure it is dark mode compatible.
        // Changing border color for a `Button` must be done with the `overrideStyle` method.
        layer.borderColor = style.borderColor(forState: state)
    }

    // MARK: - Private methods

    private func setup() {
        isAccessibilityElement = true

        titleEdgeInsets = style.paddings
        contentEdgeInsets = style.margins
        titleLabel?.font = style.font
        titleLabel?.adjustsFontForContentSizeCategory = true
        layer.cornerRadius = cornerRadius
        layer.borderWidth = style.borderWidth
        layer.borderColor = style.borderColor?.cgColor
        backgroundColor = style.bodyColor

        // Calling super because the method is effectively disabled for this class
        super.setTitleColor(style.textColor, for: .normal)
        super.setTitleColor(style.highlightedTextColor, for: .highlighted)
        super.setTitleColor(style.disabledTextColor, for: .disabled)
    }

    private func setAsLink(title: String) {
        let textRange = NSRange(location: 0, length: title.count)
        let attributedTitle = NSMutableAttributedString(string: title)

        attributedTitle.addAttribute(.foregroundColor, value: style.textColor, range: textRange)
        let underlinedAttributedTitle = NSMutableAttributedString(string: title)

        let disabledAttributedTitle = NSMutableAttributedString(string: title)
        disabledAttributedTitle.addAttribute(
            .foregroundColor,
            value: style.disabledTextColor ?? UIColor.tertiaryText,
            range: textRange
        )

        let underlineAttributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: style.highlightedTextColor ?? style.textColor
        ]
        underlinedAttributedTitle.addAttributes(underlineAttributes, range: textRange)

        super.setAttributedTitle(attributedTitle, for: .normal)
        super.setAttributedTitle(underlinedAttributedTitle, for: .highlighted)
        super.setAttributedTitle(disabledAttributedTitle, for: .disabled)
    }
}
