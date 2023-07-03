import UIKit

class ActionHeaderView: View {
    private lazy var titleLabel: Label = {
        let label = Label(style: .headlineSemibold)
        return label
    }()

    private lazy var hairlineView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = .secondaryBackground
        view.layer.cornerRadius = 1
        return view
    }()

    func configure(title: String) {
        titleLabel.text = title
    }

    let topMargin: CGFloat = 8
    let margin: CGFloat = 28
    let hairlineTopSpacing: CGFloat = 15
    let hairlineHeight: CGFloat = 2

    override func setup() {
        addSubview(titleLabel)
        addSubview(hairlineView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: topMargin),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            hairlineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: hairlineTopSpacing),
            hairlineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            hairlineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            hairlineView.heightAnchor.constraint(equalToConstant: hairlineHeight),
            hairlineView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func height(width: CGFloat) -> CGFloat {
        let width = width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        var height = directionalLayoutMargins.top

        let title = titleLabel.text ?? ""
        height += topMargin + title.height(withConstrainedWidth: width, font: titleLabel.font)
        height += hairlineTopSpacing + hairlineHeight
        height += directionalLayoutMargins.bottom

        return height
    }

}
