import UIKit
import Pinwheel

struct FontItem {
    let font: UIFont
    let title: String
}

class UIKitPinTypographyDemo: UIKitPinView {
    private let items: [FontItem] = [
        FontItem(font: .title, title: "Title"),
        FontItem(font: .titleSemibold, title: "Title Semibold"),
        FontItem(font: .subtitle, title: "Subtitle"),
        FontItem(font: .subtitleSemibold, title: "Subtitle Semibold"),
        FontItem(font: .body, title: "Body"),
        FontItem(font: .bodySemibold, title: "Body Semibold"),
        FontItem(font: .footnote, title: "Footnote"),
        FontItem(font: .footnoteSemibold, title: "Footnote Semibold"),
        FontItem(font: .caption, title: "Caption"),
        FontItem(font: .captionSemibold, title: "Caption Semibold")
    ]

    // A left-aligned VStack (not a UITableView): eager and in the view tree, so it captures as an
    // auto-layout column — the UIKit counterpart of the SwiftUI Typography demo. spacingL horizontal
    // inset, spacingM top/bottom, and 2×spacingM between rows mirror the SwiftUI per-row padding.
    override func setup() {
        let stack = UIStackView(withAutoLayout: true)
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = .spacingM * 2
        stack.isLayoutMarginsRelativeArrangement = true
        stack.insetsLayoutMarginsFromSafeArea = false
        stack.layoutMargins = UIEdgeInsets(top: .spacingM, left: .spacingL, bottom: .spacingM, right: .spacingL)
        for item in items {
            let label = UIKitPinLabel(font: item.font)
            label.text = item.title
            stack.addArrangedSubview(label)
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
