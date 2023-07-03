import UIKit

final class ActionCell: UITableViewCell {
    private lazy var titleLabel = Label(style: .body)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = contentView.frame.insetBy(dx: 28, dy: 7)
        selectedBackgroundView?.frame = selectedBackgroundView?.frame.insetBy(dx: 25.5, dy: 5) ?? .zero
    }

    func configure(withTitle title: String, isCritical: Bool, tintColor: UIColor = .primaryText) {
        titleLabel.text = title
        titleLabel.textColor = tintColor

        titleLabel.textColor = isCritical ? .criticalAction : .primaryText
        contentView.backgroundColor = isCritical ? .criticalBackground : .secondaryBackground
        selectedBackgroundView?.backgroundColor = isCritical ? .criticalAction : .tertiaryText
    }

    private func setup() {
        backgroundColor = .primaryBackground
        isAccessibilityElement = true
        contentView.layer.cornerRadius = 16
        if #available(iOS 13.0, *) {
            contentView.layer.cornerCurve = .continuous
        }

        let selectedBackgroundView = UIView()
        selectedBackgroundView.layer.cornerRadius = 17
        if #available(iOS 13.0, *) {
            selectedBackgroundView.layer.cornerCurve = .continuous
        }
        self.selectedBackgroundView = selectedBackgroundView

        contentView.addSubview(titleLabel)
        titleLabel.fillInSuperview(margin: .spacingM)    
    }
}
