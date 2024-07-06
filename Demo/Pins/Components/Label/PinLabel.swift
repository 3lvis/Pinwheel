import Pinwheel

class PinLabel: View {
    override func setup() {
        let title = Label(font: .title)
        title.text = "Title"

        let subtitle = Label(font: .subtitle)
        subtitle.text = "Subtitle"

        let body = Label(font: .body)
        body.text = "Body"

        let footnote = Label(font: .footnote)
        footnote.text = "Footnote"

        let caption = Label(font: .caption)
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
