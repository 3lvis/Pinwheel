import Pinwheel

class PinLabel: View {
    override func setup() {
        let headline = Label(style: .headline)
        headline.text = "Headline"

        let headlineSemibold = Label(style: .headlineSemibold)
        headlineSemibold.text = "Headline Semibold"

        let headlineBold = Label(style: .headlineBold)
        headlineBold.text = "Headline Bold"

        let body = Label(style: .body)
        body.text = "Body"

        let subheadline = Label(style: .subheadline)
        subheadline.text = "Subheadline"

        let subheadlineSemibold = Label(style: .subheadlineSemibold)
        subheadlineSemibold.text = "Subheadline Semibold"

        let subheadlineBold = Label(style: .subheadlineBold)
        subheadlineBold.text = "Subheadline Bold"

        let caption = Label(style: .caption)
        caption.text = "Caption"

        let stackView = UIStackView(axis: .vertical, spacing: .spacingL)
        stackView.addArrangedSubviews([
            headline,
            headlineSemibold,
            headlineBold,
            body,
            subheadline,
            subheadlineSemibold,
            subheadlineBold,
            caption,
        ])

        addSubview(stackView)
        stackView.anchorToTopSafeArea(margin: .spacingL)
    }
}
