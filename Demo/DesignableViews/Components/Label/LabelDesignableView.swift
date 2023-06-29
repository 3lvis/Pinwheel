import Designable

class LabelDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
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

        let subheadlineBold = Label(style: .subheadlineBold)
        subheadlineBold.text = "Subheadline Bold"

        let caption = Label(style: .caption)
        caption.text = "Caption"

        let stackView = UIStackView(axis: .vertical, spacing: .spacingM)
        stackView.addArrangedSubviews([
            headline,
            headlineSemibold,
            headlineBold,
            body,
            subheadline,
            subheadlineBold,
            caption,
        ])

        addSubview(stackView)
        stackView.anchorInTopSafeArea(margin: .spacingM)
    }
}
