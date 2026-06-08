import UIKit

/// Trivial themed `UILabel` subclass. Label is the one component where SwiftUI
/// and UIKit each get an independent trivial implementation fed by the same
/// `Config` provider tokens — no hosting bridge in either direction. The SwiftUI
/// counterpart is `PinLabel` (a themed `Text`).
public class UIKitPinLabel: UILabel {
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
