import UIKit
import Pinwheel

class UIPinLabelDemo: UIPinView {
    override func setup() {
        let title = UIPinLabel(font: .title)
        title.text = "Title"

        let subtitle = UIPinLabel(font: .subtitle)
        subtitle.text = "Subtitle"

        let body = UIPinLabel(font: .body)
        body.text = "Body"

        let footnote = UIPinLabel(font: .footnote)
        footnote.text = "Footnote"

        let caption = UIPinLabel(font: .caption)
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
