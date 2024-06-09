import UIKit

public class Label: UILabel {
    // MARK: - Setup

    public init(font: UIFont = .body, textColor: UIColor = .primaryText) {
        super.init(frame: .zero)
        setup(font: font, textColor: textColor)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup(font: UIFont = .body, textColor: UIColor = .primaryText) {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        adjustsFontForContentSizeCategory = true
        self.font = font
        self.textColor = textColor
    }
}
