import UIKit

public protocol TableViewCellDelegate: AnyObject {
    func tableViewCell(_ tableViewCell: TableViewCell, didChangeBoolTableViewItem boolTableViewItem: BoolTableViewItem, atIndexPath indexPath: IndexPath)
}

open class TableViewCell: UITableViewCell {
    weak var delegate: TableViewCellDelegate?

    // MARK: - Public properties

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
        label.font = .caption
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

    open lazy var switchControl: UISwitch = {
        let aSwitch = UISwitch(withAutoLayout: true)
        aSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return aSwitch
    }()

    @objc func switchChanged(sender: UISwitch) {
        if let edited = tableViewItem as? BoolTableViewItem, let indexPath = indexPath {
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

    open lazy var stackViewLeadingAnchorConstraint = stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .spacingM)
    open lazy var stackViewTrailingAnchorConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor)
    open lazy var stackViewBottomAnchorConstraint = stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -13)
    open lazy var stackViewTopAnchorConstraint = stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13)
    open lazy var detailLabelTrailingConstraint = detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
    open lazy var switchControlTrailingConstraint = switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

    // MARK: - Private properties

    private lazy var stackViewToDetailLabelConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: detailLabel.leadingAnchor, constant: -.spacingXS)
    private lazy var stackViewToSwitchControlConstraint = stackView.trailingAnchor.constraint(lessThanOrEqualTo: switchControl.leadingAnchor, constant: -.spacingXS)

    // MARK: - Setup

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    public var indexPath: IndexPath?

    public var tableViewItem: TableViewItem? {
        didSet {
            guard let viewModel = tableViewItem else { return }
            titleLabel.text = viewModel.title

            let isSelected = selectedIndexPath != nil ? selectedIndexPath == indexPath : false
            titleLabel.textColor = isSelected ? .actionText : .primaryText

            titleLabel.isEnabled = isEnabled
            selectionStyle = isEnabled ? .default : .none

            if let subtitle = viewModel.subtitle {
                subtitleLabel.text = subtitle
                subtitleLabel.isHidden = false
            } else {
                subtitleLabel.isHidden = true
            }

            if let detailText = (viewModel as? TextTableViewItem)?.detailText {
                detailLabel.text = detailText
                detailLabel.isHidden = false
                stackViewToDetailLabelConstraint.isActive = true
                switchControl.isHidden = true
                stackViewToSwitchControlConstraint.isActive = false
            } else {
                detailLabel.isHidden = true
                stackViewToDetailLabelConstraint.isActive = false

                if viewModel is BoolTableViewItem {
                    switchControl.isOn = (viewModel as? BoolTableViewItem)?.isOn ?? false
                    switchControl.isHidden = false
                    stackViewToSwitchControlConstraint.isActive = true
                } else {
                    switchControl.isHidden = true
                    stackViewToSwitchControlConstraint.isActive = false
                }
            }

            if (viewModel as? TextTableViewItem)?.hasChevron == true {
                accessoryType = .disclosureIndicator
                detailLabelTrailingConstraint.constant = -.spacingS
                switchControlTrailingConstraint.constant = -.spacingS
                stackViewTrailingAnchorConstraint.constant = -.spacingS
            } else {
                accessoryType = .none
                detailLabelTrailingConstraint.constant = -.spacingM
                switchControlTrailingConstraint.constant = -.spacingM
                stackViewTrailingAnchorConstraint.constant = -.spacingM
            }

            separatorInset = .leadingInset(.spacingM)
        }
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        detailLabel.text = nil
    }

    // MARK: - Private methods

    private func setup() {
        setDefaultSelectedBackgound()
        backgroundColor = .primaryBackground

        contentView.addSubview(stackView)
        contentView.addSubview(detailLabel)
        contentView.addSubview(switchControl)

        NSLayoutConstraint.activate([
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
