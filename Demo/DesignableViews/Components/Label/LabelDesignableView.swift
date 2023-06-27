import Designable

public class LabelDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    private func setup() {
        let headline = Label(style: .headline)
        headline.text = "headline"

        let headlineSemibold = Label(style: .headlineSemibold)
        headlineSemibold.text = "headlineSemibold"

        let headlineBold = Label(style: .headlineBold)
        headlineBold.text = "headlineBold"

        let body = Label(style: .body)
        body.text = "body"

        let subheadline = Label(style: .subheadline)
        subheadline.text = "subheadline"

        let subheadlineBold = Label(style: .subheadlineBold)
        subheadlineBold.text = "subheadlineBold"

        let caption = Label(style: .caption)
        caption.text = "caption"

        addSubview(headline)
        addSubview(headlineSemibold)
        addSubview(headlineBold)
        addSubview(body)
        addSubview(subheadline)
        addSubview(subheadlineBold)
        addSubview(caption)

        NSLayoutConstraint.activate([
            headline.topAnchor.constraint(equalTo: topAnchor, constant: .spacingL),
            headline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            headlineSemibold.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: .spacingL),
            headlineSemibold.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            headlineBold.topAnchor.constraint(equalTo: headlineSemibold.bottomAnchor, constant: .spacingL),
            headlineBold.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            body.topAnchor.constraint(equalTo: headlineBold.bottomAnchor, constant: .spacingL),
            body.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            subheadline.topAnchor.constraint(equalTo: body.bottomAnchor, constant: .spacingL),
            subheadline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            subheadlineBold.topAnchor.constraint(equalTo: subheadline.bottomAnchor, constant: .spacingL),
            subheadlineBold.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL),

            caption.topAnchor.constraint(equalTo: subheadlineBold.bottomAnchor, constant: .spacingL),
            caption.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingL)
        ])
    }
}
