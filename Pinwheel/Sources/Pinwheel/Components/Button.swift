import UIKit

public enum ButtonStyle {
    case primary
    case secondary
    case tertiary
    case custom(textColor: UIColor, backgroundColor: UIColor)

    var isPrimary: Bool {
        if case .primary = self {
            return true
        }
        return false
    }
}

public class Button: UIButton {
    private static let buttonWidth = round(100.0 * sizeRatio)
    public static var sizeRatio: CGFloat {
        let screenHeight = UIScreen.main.bounds.height

        if screenHeight > 693 {
            return 1.0
        } else {
            return 0.8
        }
    }
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

    let font: UIFont
    public init(title: String? = nil, symbol: String? = nil, font: UIFont = .bodySemibold, style: ButtonStyle = .primary) {
        self.title = title
        self.font = font
        self.style = style
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

        if let superview = superview, let _ = title {
            widthAnchor.constraint(greaterThanOrEqualToConstant: Button.buttonWidth).isActive = true
            widthAnchor.constraint(lessThanOrEqualTo: superview.widthAnchor, constant: -.spacingXL).isActive = true

            setContentHuggingPriority(.defaultHigh, for: .horizontal)
            setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
    }

    private func addSymbolToTitle(symbol: String) {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: self.font.pointSize, weight: self.font.weight.symbolWeight)
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
        switch style {
        case .tertiary:
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
        default: setTitle(title, for: .normal)
        }
        invalidateIntrinsicContentSize()
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

            invalidateIntrinsicContentSize()
        } else {
            subviews.forEach {
                if let activityIndicator = $0 as? UIActivityIndicatorView {
                    activityIndicator.removeFromSuperview()
                }
            }
            titleLabelCenterXConstraint?.constant = 0

            self.layoutIfNeeded()

            invalidateIntrinsicContentSize()
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
        case .secondary, .tertiary, .custom(_, _):
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @objc private func updateStyle() {
        marginInsets = UIEdgeInsets(top: .spacingXS, left: .spacingM, bottom: .spacingXS, right: .spacingM)

        titleLabel?.font = self.font
        layer.cornerRadius = .spacingM
        layer.cornerCurve = .continuous
        if style.isPrimary {
            setTitleColor(.primaryBackground, for: .disabled)
        } else {
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
        case .custom(let textColor, let aBackgroundColor):
            if isEnabled {
                configureButtonColors(
                    titleColor: textColor,
                    backgroundColor: aBackgroundColor
                )
            } else {
                setTitleColor(textColor.withAlphaComponent(0.5), for: .disabled)
                backgroundColor = aBackgroundColor.withAlphaComponent(0.5)
            }
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
