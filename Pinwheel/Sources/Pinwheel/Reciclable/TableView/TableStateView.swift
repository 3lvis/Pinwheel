import UIKit

public protocol TableStateViewDelegate: AnyObject {
    func tableStateViewDidSelectAction(_ tableStateView: TableStateView)
}

public class TableStateView: View {
    public weak var delegate: TableStateViewDelegate?

    private lazy var titleLabel: Label = {
        let label = Label(font: .subtitle)
        label.text = "Ready to Move?"
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: Label = {
        let label = Label(textColor: .secondaryText)
        label.text = "Kick things off with your first booking."
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var actionButton: Button = {
        let button = Button(title: "New booking", style: .secondary)
        button.alpha = 1
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(withAutoLayout: true)
        view.hidesWhenStopped = true
        return view
    }()

    @objc private func buttonAction() {
        self.delegate?.tableStateViewDidSelectAction(self)
    }

    public var title: String? {
        didSet {
            self.titleLabel.text = self.title
        }
    }

    public var subtitle: String? {
        didSet {
            self.subtitleLabel.text = self.subtitle
        }
    }

    public var actionTitle: String? {
        didSet {
            self.actionButton.title = actionTitle
        }
    }

    public var isActionHidden: Bool = false {
        didSet {
            actionButton.alpha = isActionHidden ? 0 : 1
        }
    }

    public var isLoading: Bool = false {
        didSet {
            if isLoading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        }
    }

    public override func setup() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(actionButton)
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: .spacingM).withPriority(.defaultLow),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -.spacingS),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -.spacingXL),

            loadingIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -.spacingS),

            subtitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .spacingM),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),

            actionButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: .spacingL),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -.spacingM).withPriority(.defaultLow),
        ])
    }
}
