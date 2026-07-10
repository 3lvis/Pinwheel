import UIKit

final class FloatingButton: UIButton {
    private let style: FloatingButton.Style
    override var isHighlighted: Bool { didSet { updateBackgroundColor() }}
    override var isSelected: Bool { didSet { updateBackgroundColor() }}

    var itemsCount: Int = 0 {
        didSet {
            badgeLabel.text = "\(itemsCount)"
            badgeView.isHidden = itemsCount == 0
        }
    }

    private lazy var badgeView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = style.badgeBackgroundColor
        view.layer.cornerRadius = style.badgeSize / 2
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var badgeLabel: UILabel = {
        let label = UIPinLabel(font: .subtitle)
        label.textColor = style.badgeTextColor
        label.textAlignment = .center
        return label
    }()

    override convenience init(frame: CGRect) {
        self.init(frame: frame, style: .default)
    }

    init(frame: CGRect, style: FloatingButton.Style) {
        self.style = style
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if transform == .identity {
            layer.cornerRadius = frame.height / 2
        }
        updateLayerColors()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        updateBackgroundColor()
        updateLayerColors()
        layer.shadowOpacity = 1
        layer.borderWidth = style.borderWidth
        badgeView.backgroundColor = style.badgeBackgroundColor
        badgeView.layer.cornerRadius = style.badgeSize / 2
        badgeLabel.textColor = style.badgeTextColor
        tintColor = style.tintColor
        layer.shadowOffset = style.shadowOffset
        layer.shadowRadius = style.shadowRadius
        setTitleColor(style.titleColor, for: .normal)

        contentMode = .center

        titleLabel?.font = .subtitle

        addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        badgeLabel.fillInSuperview()

        NSLayoutConstraint.activate([
            badgeView.widthAnchor.constraint(equalToConstant: style.badgeSize),
            badgeView.heightAnchor.constraint(equalToConstant: style.badgeSize),
            badgeView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: .spacingXS),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .spacingXS),
        ])
    }

    private func updateBackgroundColor() {
        backgroundColor = isSelected || isHighlighted ? style.highlightedBackgroundColor : style.primaryBackgroundColor
    }

    private func updateLayerColors() {
        layer.shadowColor = style.shadowColor.cgColor
        layer.borderColor = style.borderColor?.cgColor
    }
}
