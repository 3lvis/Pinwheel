import UIKit

public protocol UIKitPinTableViewCellDelegate: AnyObject {
    func tableViewCell(_ tableViewCell: UIKitPinTableViewCell, didChangeBoolTableViewItem boolTableViewItem: UIKitPinBoolTableViewItem, atIndexPath indexPath: IndexPath)
}

open class UIKitPinTableViewCell: UITableViewCell {
    weak var delegate: UIKitPinTableViewCellDelegate?

    open var selectedIndexPath: IndexPath?
    open var isEnabled: Bool = true

    open lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = .body
        label.textColor = .primaryText
        label.numberOfLines = 0
        return label
    }()

    open lazy var subtitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = .footnote
        label.textColor = .primaryText
        label.numberOfLines = 0
        return label
    }()

    open lazy var detailLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = .body
        label.textColor = .secondaryText
        return label
    }()

    open lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .center
        imageView.tintColor = .actionText
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: .body)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }()

    open lazy var switchControl: UISwitch = {
        let aSwitch = UISwitch(withAutoLayout: true)
        aSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return aSwitch
    }()

    @objc func switchChanged(sender: UISwitch) {
        if let edited = tableViewItem as? UIKitPinBoolTableViewItem, let indexPath = indexPath {
            edited.isOn = sender.isOn
            delegate?.tableViewCell(self, didChangeBoolTableViewItem: edited, atIndexPath: indexPath)
        }
    }

    open lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 2
        stackView.axis = .vertical
        return stackView
    }()

    open lazy var stackViewLeadingAnchorConstraint = stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingL)
    private lazy var iconLeadingConstraint = iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingL)
    private lazy var stackViewToIconConstraint = stackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: .spacingS)
    open lazy var stackViewTrailingAnchorConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
    open lazy var stackViewBottomAnchorConstraint = stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13)
    open lazy var stackViewTopAnchorConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13)
    open lazy var detailLabelTrailingConstraint = detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
    open lazy var switchControlTrailingConstraint = switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

    private lazy var stackViewToDetailLabelConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -.spacingXS)
    private lazy var stackViewToSwitchControlConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: switchControl.leadingAnchor, constant: -.spacingXS)

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var indexPath: IndexPath?

    public var tableViewItem: UIKitPinTableViewItem? {
        didSet {
            guard let viewModel = tableViewItem else { return }
            titleLabel.text = viewModel.title

            let isSelected = selectedIndexPath != nil ? selectedIndexPath == indexPath : false
            titleLabel.textColor = isSelected ? .actionText : .primaryText

            titleLabel.isEnabled = isEnabled
            selectionStyle = isEnabled ? .default : .none

            if let icon = viewModel.icon {
                iconImageView.image = icon
                iconImageView.isHidden = false
                iconImageView.tintColor = isEnabled ? .actionText : .secondaryText
                stackViewLeadingAnchorConstraint.isActive = false
                iconLeadingConstraint.isActive = true
                stackViewToIconConstraint.isActive = true
            } else {
                iconImageView.image = nil
                iconImageView.isHidden = true
                iconLeadingConstraint.isActive = false
                stackViewToIconConstraint.isActive = false
                stackViewLeadingAnchorConstraint.isActive = true
            }

            if let subtitle = viewModel.subtitle {
                subtitleLabel.text = subtitle
                subtitleLabel.isHidden = false
            } else {
                subtitleLabel.isHidden = true
            }

            if let detailText = (viewModel as? UIKitPinTextTableViewItem)?.detailText {
                detailLabel.text = detailText
                detailLabel.isHidden = false
                stackViewToDetailLabelConstraint.isActive = true
                switchControl.isHidden = true
                stackViewToSwitchControlConstraint.isActive = false
            } else {
                detailLabel.isHidden = true
                stackViewToDetailLabelConstraint.isActive = false

                if viewModel is UIKitPinBoolTableViewItem {
                    switchControl.isOn = (viewModel as? UIKitPinBoolTableViewItem)?.isOn ?? false
                    switchControl.isHidden = false
                    stackViewToSwitchControlConstraint.isActive = true
                } else {
                    switchControl.isHidden = true
                    stackViewToSwitchControlConstraint.isActive = false
                }
            }

            if (viewModel as? UIKitPinTextTableViewItem)?.hasChevron == true {
                accessoryType = .disclosureIndicator
                detailLabelTrailingConstraint.constant = -.spacingS
                switchControlTrailingConstraint.constant = -.spacingS
                stackViewTrailingAnchorConstraint.constant = -.spacingS
            } else {
                accessoryType = .none
                detailLabelTrailingConstraint.constant = -.spacingL
                switchControlTrailingConstraint.constant = -.spacingL
                stackViewTrailingAnchorConstraint.constant = -.spacingL
            }

            separatorInset = .leadingInset(.spacingL)
        }
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        detailLabel.text = nil
        iconImageView.image = nil
    }

    private func setup() {
        setDefaultSelectedBackgound()
        backgroundColor = .primaryBackground

        contentView.addSubview(iconImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(detailLabel)
        contentView.addSubview(switchControl)

        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: .spacingXL),
            iconImageView.heightAnchor.constraint(equalToConstant: .spacingXL),

            stackViewTopAnchorConstraint,
            stackViewLeadingAnchorConstraint,
            stackViewTrailingAnchorConstraint,
            stackViewBottomAnchorConstraint,

            detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            detailLabelTrailingConstraint,

            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchControlTrailingConstraint
            ])
    }
}
