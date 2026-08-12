import UIKit

public class UIPinLabel: UILabel {
    private var textStyle: PinTextStyle = .body

    public init(font: PinTextStyle = .body, textColor: UIColor = .primaryText) {
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

    private func setup(font: PinTextStyle = .body, textColor: UIColor = .primaryText) {
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        adjustsFontForContentSizeCategory = true
        textStyle = font
        self.textColor = textColor
        applyTextStyle()
        registerForTraitChanges([PinwheelThemeTrait.self]) { (label: UIPinLabel, _: UITraitCollection) in
            label.applyTextStyle()
        }
    }

    private func applyTextStyle() {
        font = textStyle.uiFont(in: traitCollection[PinwheelThemeTrait.self])
    }
}
