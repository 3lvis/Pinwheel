import UIKit

public enum ButtonStyle {
    case primary
    case secondary
    case tertiary
}

public class Button: UIButton {
    public static var sizeRatio: CGFloat {
        let screenHeight = UIScreen.main.bounds.height

        if screenHeight > 693 {
            return 1.0
        } else {
            return 0.8
        }
    }
    public static let buttonHeight = round(48.0 * sizeRatio)
    private static let buttonWidth = round(160.0 * sizeRatio)
    public var isLoading = false
    private var style: ButtonStyle
    private var titleLabelCenterXConstraint: NSLayoutConstraint?

    private var marginInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }

    public var title: String? {
        didSet {
            updateTitle()
        }
    }

    public override var isEnabled: Bool {
        didSet {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.updateStyle()
            })
        }
    }

    public init(title: String? = nil, symbol: String? = nil, style: ButtonStyle = .primary) {
        self.style = style
        self.title = title
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false

        updateStyle()

        if let aSymbol = symbol {
            addSymbolToTitle(symbol: aSymbol)
        } else {
            updateTitle()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        heightAnchor.constraint(equalToConstant: Button.buttonHeight).isActive = true

        if let superview = superview, let _ = title {
            widthAnchor.constraint(greaterThanOrEqualToConstant: Button.buttonWidth).isActive = true
            widthAnchor.constraint(lessThanOrEqualTo: superview.widthAnchor, constant: -.spacingXL).isActive = true
        }
    }

    private func addSymbolToTitle(symbol: String) {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let symbolImage = UIImage(systemName: symbol, withConfiguration: symbolConfiguration)?.withRenderingMode(.alwaysTemplate)
        let symbolAttachment = NSTextAttachment()
        symbolAttachment.image = symbolImage
        let symbolString = NSAttributedString(attachment: symbolAttachment)
        if let aTitle = title {
            let textWithSymbol = NSMutableAttributedString(string: "\(aTitle) ")
            textWithSymbol.append(symbolString)
            setAttributedTitle(textWithSymbol, for: .normal)
        } else {
            setAttributedTitle(symbolString, for: .normal)
        }
    }

    private func updateTitle() {
        if style == .tertiary {
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.secondaryText,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            let normalAttributedTitle = NSAttributedString(string: title ?? "", attributes: normalAttributes)
            setAttributedTitle(normalAttributedTitle, for: .normal)

            let disabledAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.tertiaryText,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            let disabledAttributedTitle = NSAttributedString(string: title ?? "", attributes: disabledAttributes)
            setAttributedTitle(disabledAttributedTitle, for: .disabled)
        } else {
            setTitle(title, for: .normal)
        }
    }

    public func showActivityIndicator(_ shouldShow: Bool) {
        isLoading = shouldShow

        if shouldShow {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.color = .primaryBackground
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
                activityIndicator.leadingAnchor.constraint(equalTo: titleLabel!.trailingAnchor, constant: .spacingS)
            ])
            activityIndicator.startAnimating()

            self.layoutIfNeeded()

            if titleLabelCenterXConstraint == nil {
                titleLabelCenterXConstraint = self.constraints.first(where: {
                    $0.firstItem === titleLabel && $0.firstAttribute == .centerX
                })
            }

            let value = -activityIndicator.bounds.width / 2 - .spacingXS
            titleLabelCenterXConstraint?.constant = value
        } else {
            subviews.forEach {
                if let activityIndicator = $0 as? UIActivityIndicatorView {
                    activityIndicator.removeFromSuperview()
                }
            }
            titleLabelCenterXConstraint?.constant = 0

            self.layoutIfNeeded()
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
        }

        switch style {
        case .primary:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .secondary, .tertiary:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @objc private func updateStyle() {
        marginInsets = UIEdgeInsets(top: 0, left: .spacingM, bottom: 0, right: .spacingM)
        titleLabel?.font = .subtitle

        if style != .tertiary {
            layer.cornerRadius = .spacingM
            layer.cornerCurve = .continuous
            setTitleColor(.tertiaryText, for: .disabled)
        }

        switch style {
        case .primary:
            if isEnabled {
                configureButtonColors(
                    titleColor: .primaryBackground,
                    backgroundColor: .actionText
                )
            } else {
                backgroundColor = .actionBackground
            }
        case .secondary:
            if isEnabled {
                configureButtonColors(
                    titleColor: .primaryText,
                    backgroundColor: .secondaryBackground
                )
            } else {
                backgroundColor = .secondaryBackground
            }
        case .tertiary:
            configureButtonColors(
                titleColor: .secondaryText,
                backgroundColor: .clear
            )
        }
    }

    private func configureButtonColors(
        titleColor: UIColor,
        backgroundColor: UIColor
    ) {
        setTitleColor(titleColor, for: .normal)
        self.backgroundColor = backgroundColor
    }

    public override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += marginInsets.left + marginInsets.right
        if isLoading {
            let activityIndicatorWidth = 20.0
            size.width += activityIndicatorWidth + .spacingS
        }
        size.height += marginInsets.top + marginInsets.bottom
        return size
    }
}
