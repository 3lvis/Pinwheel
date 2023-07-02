import UIKit

public class Label: UILabel {

    // MARK: - Public properties

    public private(set) var style: Style?

    // MARK: - Setup

    public init(style: Style, textColor: UIColor = .primaryText) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.style = style
        setup(textColor: textColor)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup(textColor: UIColor = .primaryText) {
        isAccessibilityElement = true

        accessibilityLabel = text
        font = style?.font
        self.textColor = textColor
        adjustsFontForContentSizeCategory = true
    }
}
