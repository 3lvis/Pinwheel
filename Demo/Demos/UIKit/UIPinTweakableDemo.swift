import UIKit
import Pinwheel

class UIPinTweakableDemo: UIPinView, Tweakable {
    private let text = "Tweak this label."
    private let alignmentTitles = ["Leading", "Center", "Trailing"]
    private var alignmentIndex = 1
    private var isUppercase = false

    lazy var tweaks: [Tweak] = {
        return [
            SelectTweak(
                title: "Alignment",
                options: alignmentTitles,
                chosenOption: { self.alignmentIndex },
                action: { self.alignmentIndex = $0; self.reload() }
            ),
            BoolTweak(title: "Uppercase") { isUppercase in
                self.isUppercase = isUppercase
                self.reload()
            },
            TextTweak(title: "Reset") {
                self.alignmentIndex = 1
                self.isUppercase = false
                self.reload()
            }
        ]
    }()

    lazy var titleLabel: UIPinLabel = {
        let label = UIPinLabel(font: .body)
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
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacing8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacing8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        reload()
    }

    private var alignments: [NSTextAlignment] {
        let trailing: NSTextAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        return [.natural, .center, trailing]
    }

    private func reload() {
        titleLabel.text = isUppercase ? text.uppercased() : text
        titleLabel.textAlignment = alignments[alignmentIndex]
    }
}
