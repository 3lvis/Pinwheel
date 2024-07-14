import UIKit

public protocol StateViewDelegate: AnyObject {
    func stateViewDidSelectAction(_ stateView: StateView)
}

public enum StateViewState {
    case loading(title: String, subtitle: String)
    case loaded
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)
}

public class StateView: View {
    public weak var delegate: StateViewDelegate?

    private lazy var titleLabel: Label = {
        let label = Label(font: .subtitle)
        label.text = "Title"
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: Label = {
        let label = Label(textColor: .secondaryText)
        label.text = "Subtitle"
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var actionButton: Button = {
        let button = Button(title: "Action", style: .secondary)
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
        self.delegate?.stateViewDidSelectAction(self)
    }

    public var state: StateViewState = .loaded {
        didSet {
            switch state {
            case .loading(let title, let subtitle):
                self.alpha = 1
                self.titleLabel.text = title
                self.subtitleLabel.text = subtitle
                self.actionButton.alpha = 0
                self.loadingIndicator.startAnimating()
            case .loaded:
                self.alpha = 0
            case .empty(let title, let subtitle):
                self.alpha = 1
                self.titleLabel.text = title
                self.subtitleLabel.text = subtitle
                self.actionButton.alpha = 0
                self.loadingIndicator.stopAnimating()
            case .failed(let title, let subtitle, let actionTitle):
                self.alpha = 1
                self.titleLabel.text = title
                self.subtitleLabel.text = subtitle
                self.actionButton.title = actionTitle
                self.actionButton.alpha = 1
                self.loadingIndicator.stopAnimating()
            }
        }
    }

    public override func setup() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(actionButton)
        addSubview(loadingIndicator)
        alpha = 0

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
