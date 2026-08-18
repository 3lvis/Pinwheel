import UIKit
import Pinwheel

struct FontItem {
    let font: PinTextStyle
    let title: String
}

class UIPinTypographyDemo: UIPinView {
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

    override func setup() {
        let stack = UIStackView(withAutoLayout: true)
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = .spacing3 * 2
        stack.isLayoutMarginsRelativeArrangement = true
        stack.insetsLayoutMarginsFromSafeArea = false
        stack.layoutMargins = UIEdgeInsets(top: .spacing3, left: .spacing4, bottom: .spacing3, right: .spacing4)
        for item in items {
            let label = UIPinLabel(font: item.font)
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
