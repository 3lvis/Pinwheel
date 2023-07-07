import UIKit

public class Label: UILabel {

    // MARK: - Public properties

    public private(set) var style: Style = .body

    // MARK: - Setup

    public init(style: Style = .body, textColor: UIColor = .primaryText) {
        super.init(frame: .zero)
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
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityLabel = text
        adjustsFontForContentSizeCategory = true

        font = self.style.font
        self.textColor = textColor
    }
}
