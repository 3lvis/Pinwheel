import UIKit
import Pinwheel

class UIKitPinLabelDemo: UIKitPinView {
    override func setup() {
        let title = UIKitPinLabel(font: .title)
        title.text = "Title"

        let subtitle = UIKitPinLabel(font: .subtitle)
        subtitle.text = "Subtitle"

        let body = UIKitPinLabel(font: .body)
        body.text = "Body"

        let footnote = UIKitPinLabel(font: .footnote)
        footnote.text = "Footnote"

        let caption = UIKitPinLabel(font: .caption)
        caption.text = "Caption"

        let stackView = UIStackView(axis: .vertical, spacing: .spacingL)
        stackView.addArrangedSubviews([
            title,
            subtitle,
            body,
            footnote,
            caption
        ])

        addSubview(stackView)
        stackView.anchorToTopSafeArea(margin: .spacingL)
    }
}
