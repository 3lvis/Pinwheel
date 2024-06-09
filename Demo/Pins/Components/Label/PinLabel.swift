import Pinwheel

class PinLabel: View {
    override func setup() {
        let headline = Label(font: .headline)
        headline.text = "Headline"

        let headlineSemibold = Label(font: .headlineSemibold)
        headlineSemibold.text = "Headline Semibold"

        let headlineBold = Label(font: .headlineBold)
        headlineBold.text = "Headline Bold"

        let body = Label(font: .body)
        body.text = "Body"

        let subheadline = Label(font: .subheadline)
        subheadline.text = "Subheadline"

        let subheadlineSemibold = Label(font: .subheadlineSemibold)
        subheadlineSemibold.text = "Subheadline Semibold"

        let subheadlineBold = Label(font: .subheadlineBold)
        subheadlineBold.text = "Subheadline Bold"

        let caption = Label(font: .caption)
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
