import UIKit
import Pinwheel

class UIPinTweakableDemo: UIPinView, Tweakable {
    lazy var tweaks: [Tweak] = {
        let option1 = TextTweak(title: "Option 1") {
            self.titleLabel.text = "You chose Option 1."
        }

        let option2 = TextTweak(title: "Option 2", description: "Description 2") {
            self.titleLabel.text = "You chose Option 2."
        }

        let option3 = BoolTweak(title: "Option 3", description: "Toggle-backed option") { isOn in
            self.titleLabel.text = "Option 3 is \(isOn ? "on" : "off")."
        }

        return [option1, option2, option3]
    }()

    lazy var titleLabel: UIPinLabel = {
        let label = UIPinLabel(font: .body)
        label.text = "Tap the button and choose an option."
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // A centered stack (not a bare fill-pinned label) so the capture reads it as an auto-layout column,
    // matching the SwiftUI demo in every state — the tweaks only swap the label's text.
    override func setup() {
        let stack = UIStackView(arrangedSubviews: [titleLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingXXL),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingXXL),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
