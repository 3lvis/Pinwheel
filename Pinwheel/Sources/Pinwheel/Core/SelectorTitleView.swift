import UIKit

protocol SelectorTitleViewDelegate: AnyObject {
    func selectorTitleViewDidSelectButton(_ view: SelectorTitleView)
}

class SelectorTitleView: UIView {
    // MARK: - Public

    enum ArrowDirection {
        case up
        case down
    }

    weak var delegate: SelectorTitleViewDelegate?

    var arrowDirection: ArrowDirection = .down {
        didSet {
            updateArrowDirection()
        }
    }

    var title: String? {
        didSet {
            let font: UIFont = .body
            var updatedConfiguration = button.configuration
            updatedConfiguration?.attributedTitle = AttributedString(title ?? "", attributes: AttributeContainer([NSAttributedString.Key.font : font]))
            button.configuration = updatedConfiguration
        }
    }

    // MARK: - Private

    private var isEnabled: Bool = true {
        didSet {
            button.isEnabled = isEnabled
        }
    }

    private lazy var titleLabel: Label = {
        let label = Label(font: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.text = heading
        label.textColor = .secondaryText
        return label
    }()

    private lazy var button: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = .spacingXS
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: titleLabel.font.pointSize,
            leading: .spacingS,
            bottom: 0,
            trailing: .spacingS
        )
        configuration.imagePlacement = .leading

        let button = UIButton(configuration: configuration, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.semanticContentAttribute = .forceRightToLeft
        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)

        return button
    }()

    private var heading: String?

    // MARK: - Init

    init(heading: String) {
        self.heading = heading
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        updateArrowDirection()

        backgroundColor = .primaryBackground

        updateButtonColor()
        addSubview(button)
        button.fillInSuperview()

        if heading != nil {
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor),
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
        }
    }

    // MARK: - Actions

    @objc private func handleButtonTap() {
        delegate?.selectorTitleViewDidSelectButton(self)
    }

    // MARK: - Public

    func updateButtonColor(_ buttonColor: UIColor = .actionText, buttonDisabledColor: UIColor = .tertiaryText) {
        button.setTitleColor(buttonColor, for: .normal)
        button.setTitleColor(buttonColor.withAlphaComponent(0.5), for: .highlighted)
        button.setTitleColor(buttonColor.withAlphaComponent(0.5), for: .selected)
        button.setTitleColor(buttonDisabledColor, for: .disabled)
        button.tintColor = buttonColor
    }

    // MARK: - Private

    private func updateArrowDirection() {
        let imageName: String = arrowDirection == .up ? "chevron.up" : "chevron.down"
        let weightConfiguration = UIImage.SymbolConfiguration(weight: .medium)
        let sizeConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote)
        let configuration = sizeConfiguration.applying(weightConfiguration)
        let image = UIImage(systemName: imageName, withConfiguration: configuration)!
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
    }

}
