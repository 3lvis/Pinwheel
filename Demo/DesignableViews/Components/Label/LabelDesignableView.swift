import Designable

public class LabelDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder aDecoder: NSCoder) { fatalError() }

    private func setup() {
        let topSpacing: CGFloat = 32
        let interimSpacing: CGFloat = 0


        let labelBodyStrong = Label(style: .bodyStrong)
        let labelDetailStrong = Label(style: .detailStrong)
        let labelCaptionStrong = Label(style: .captionStrong)
        let labelCaption = Label(style: .caption)
        let labelBody = Label(style: .body)
        let labelDetail = Label(style: .detail)

        let testStyle: Label.Style = .body
        let multilineLabel = Label(style: testStyle)
        let label1 = Label(style: testStyle)
        let label2 = Label(style: testStyle)
        let label3 = Label(style: testStyle)
        let labelWide = Label(style: .body)

        labelBodyStrong.translatesAutoresizingMaskIntoConstraints = false
        labelDetailStrong.translatesAutoresizingMaskIntoConstraints = false
        labelCaptionStrong.translatesAutoresizingMaskIntoConstraints = false
        labelCaption.translatesAutoresizingMaskIntoConstraints = false
        labelBody.translatesAutoresizingMaskIntoConstraints = false
        labelDetail.translatesAutoresizingMaskIntoConstraints = false

        multilineLabel.translatesAutoresizingMaskIntoConstraints = false
        multilineLabel.numberOfLines = 0
        label1.translatesAutoresizingMaskIntoConstraints = false
        label2.translatesAutoresizingMaskIntoConstraints = false
        label3.translatesAutoresizingMaskIntoConstraints = false
        labelWide.translatesAutoresizingMaskIntoConstraints = false
        labelWide.textAlignment = .center

        addSubview(labelBodyStrong)
        addSubview(labelDetailStrong)
        addSubview(labelCaptionStrong)
        addSubview(labelCaption)
        addSubview(labelBody)
        addSubview(labelDetail)

        addSubview(multilineLabel)
        addSubview(label1)
        addSubview(label2)
        addSubview(label3)
        addSubview(labelWide)

        NSLayoutConstraint.activate([
            labelBodyStrong.topAnchor.constraint(equalTo: topAnchor, constant: interimSpacing),
            labelBodyStrong.leadingAnchor.constraint(equalTo: leadingAnchor),

            labelDetailStrong.topAnchor.constraint(equalTo: labelBodyStrong.bottomAnchor, constant: interimSpacing),
            labelDetailStrong.leadingAnchor.constraint(equalTo: labelBodyStrong.leadingAnchor),

            labelCaptionStrong.topAnchor.constraint(equalTo: labelDetailStrong.bottomAnchor, constant: interimSpacing),
            labelCaptionStrong.leadingAnchor.constraint(equalTo: labelDetailStrong.leadingAnchor),

            labelCaption.topAnchor.constraint(equalTo: labelCaptionStrong.bottomAnchor, constant: interimSpacing),
            labelCaption.leadingAnchor.constraint(equalTo: labelCaptionStrong.leadingAnchor),

            labelBody.topAnchor.constraint(equalTo: labelCaption.bottomAnchor, constant: interimSpacing),
            labelBody.leadingAnchor.constraint(equalTo: labelCaption.leadingAnchor),

            labelDetail.topAnchor.constraint(equalTo: labelBody.bottomAnchor, constant: interimSpacing),
            labelDetail.leadingAnchor.constraint(equalTo: labelBody.leadingAnchor),

            label1.topAnchor.constraint(equalTo: labelDetail.bottomAnchor, constant: topSpacing),
            label1.leadingAnchor.constraint(equalTo: labelDetail.leadingAnchor),

            label2.topAnchor.constraint(equalTo: label1.bottomAnchor, constant: 0),
            label2.leadingAnchor.constraint(equalTo: label1.leadingAnchor),

            label3.topAnchor.constraint(equalTo: label2.bottomAnchor, constant: 0),
            label3.leadingAnchor.constraint(equalTo: label2.leadingAnchor),

            multilineLabel.leadingAnchor.constraint(equalTo: label1.trailingAnchor, constant: 4),
            multilineLabel.topAnchor.constraint(equalTo: label1.topAnchor),
            multilineLabel.widthAnchor.constraint(equalToConstant: 50), // used to force a linebreak

            labelWide.topAnchor.constraint(equalTo: label3.bottomAnchor, constant: 16),
            labelWide.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            labelWide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            labelWide.heightAnchor.constraint(equalToConstant: 40)
        ])

        label1.text = "Test"
        label2.text = "Test"
        label3.text = "Test"
        multilineLabel.text = "Test Test Test"
        labelWide.text = "Test center"

        labelBodyStrong.text = "Label Body Strong"
        labelDetailStrong.text = "Label Detail Strong"
        labelCaptionStrong.text = "Label Caption Strong"
        labelCaption.text = "Label Caption"
        labelBody.text = "Label Body"
        labelDetail.text = "Label Detail"
    }
}
