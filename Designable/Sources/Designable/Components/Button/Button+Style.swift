import UIKit

public extension Button {
    /// Convenience grouping of button state related properties
    struct StateStyle: Equatable {
        let textColor: UIColor?
        let backgroundColor: UIColor?
        let borderColor: UIColor?
    }

    struct Style: Equatable {
        let bodyColor: UIColor
        let borderWidth: CGFloat
        let borderColor: UIColor?
        let textColor: UIColor
        let highlightedBodyColor: UIColor?
        let highlightedBorderColor: UIColor?
        let highlightedTextColor: UIColor?
        let disabledBodyColor: UIColor?
        let disabledBorderColor: UIColor?
        let disabledTextColor: UIColor?
        let margins: UIEdgeInsets
        let font = UIFont.bodyStrong

        var paddings = UIEdgeInsets(vertical: .spacingXS, horizontal: 0)

        init(
            bodyColor: UIColor,
            borderWidth: CGFloat,
            borderColor: UIColor?,
            textColor: UIColor,
            highlightedBodyColor: UIColor?,
            highlightedBorderColor: UIColor?,
            highlightedTextColor: UIColor?,
            disabledBodyColor: UIColor?,
            disabledBorderColor: UIColor?,
            disabledTextColor: UIColor?,
            margins: UIEdgeInsets = UIEdgeInsets(
                vertical: .spacingS,
                horizontal: .spacingM
            )
        ) {
            self.bodyColor = bodyColor
            self.borderWidth = borderWidth
            self.borderColor = borderColor
            self.textColor = textColor
            self.highlightedBodyColor = highlightedBodyColor
            self.highlightedBorderColor = highlightedBorderColor
            self.highlightedTextColor = highlightedTextColor
            self.disabledBodyColor = disabledBodyColor
            self.disabledBorderColor = disabledBorderColor
            self.disabledTextColor = disabledTextColor
            self.margins = margins
        }

        init(
            borderWidth: CGFloat,
            stateStyles: [UIControl.State: StateStyle],
            margins: UIEdgeInsets = UIEdgeInsets(
                vertical: .spacingS,
                horizontal: .spacingM
            )
        ) {
            self.borderWidth = borderWidth

            self.bodyColor = stateStyles[.normal]?.backgroundColor ?? .primaryBackground
            self.borderColor = stateStyles[.normal]?.borderColor
            self.textColor = stateStyles[.normal]?.textColor ?? .primaryAction

            self.highlightedBodyColor = stateStyles[.highlighted]?.backgroundColor
            self.highlightedBorderColor = stateStyles[.highlighted]?.borderColor
            self.highlightedTextColor = stateStyles[.highlighted]?.textColor

            self.disabledBodyColor = stateStyles[.disabled]?.backgroundColor
            self.disabledBorderColor = stateStyles[.disabled]?.borderColor
            self.disabledTextColor = stateStyles[.disabled]?.textColor

            self.margins = margins
        }

        func backgroundColor(forState state: UIControl.State) -> UIColor? {
            switch state {
            case .highlighted:
                return highlightedBodyColor
            case .disabled:
                return disabledBodyColor
            default:
                return bodyColor
            }
        }

        func borderColor(forState state: UIControl.State) -> CGColor? {
            switch state {
            case .highlighted:
                return highlightedBorderColor?.cgColor
            case .disabled:
                return disabledBorderColor?.cgColor
            default:
                return borderColor?.cgColor
            }
        }

        /// Given an existing style, this helps to create a new one overriding some of the values of the original style
        /// This method is intended for styles for concrete cases rather than default styles like `callToAction`
        public func overrideStyle(
            bodyColor: UIColor? = nil,
            borderWidth: CGFloat? = nil,
            borderColor: UIColor? = nil,
            textColor: UIColor? = nil,
            highlightedBodyColor: UIColor? = nil,
            highlightedBorderColor: UIColor? = nil,
            highlightedTextColor: UIColor? = nil,
            disabledBodyColor: UIColor? = nil,
            disabledBorderColor: UIColor? = nil,
            disabledTextColor: UIColor? = nil,
            margins: UIEdgeInsets? = nil
        ) -> Style {
            Style(
                bodyColor: bodyColor ?? self.bodyColor,
                borderWidth: borderWidth ?? self.borderWidth,
                borderColor: borderColor ?? self.borderColor,
                textColor: textColor ?? self.textColor,
                highlightedBodyColor: highlightedBodyColor ?? self.highlightedBodyColor,
                highlightedBorderColor: highlightedBorderColor ?? self.highlightedBorderColor,
                highlightedTextColor: highlightedTextColor ?? self.highlightedTextColor,
                disabledBodyColor: disabledBodyColor ?? self.disabledBodyColor,
                disabledBorderColor: disabledBorderColor ?? self.disabledBorderColor,
                disabledTextColor: disabledTextColor ?? self.disabledTextColor,
                margins: margins ?? self.margins
            )
        }
    }
}

// MARK: - Styles
public extension Button.Style {
    static var `default`: Button.Style {
        Button.Style(
            borderWidth: 2.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .primaryText,
                    backgroundColor: .primaryBackground,
                    borderColor: .primaryText
                ),
                .highlighted: Button.StateStyle(
                    textColor: nil,
                    backgroundColor: UIColor.primaryBackground.withAlphaComponent(0.3),
                    borderColor: .primaryAction
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: nil,
                    borderColor: .tertiaryText
                )
            ]
        )
    }

    static var flat: Button.Style {
        Button.Style(
            borderWidth: 0.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .primaryText,
                    backgroundColor: .clear,
                    borderColor: nil
                ),
                .highlighted: Button.StateStyle(
                    textColor: .primaryAction.withAlphaComponent(0.8),
                    backgroundColor: nil,
                    borderColor: nil
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: nil,
                    borderColor: nil
                )
            ]
        )
    }

    static var link: Button.Style {
        Button.Style(
            borderWidth: 0.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .primaryAction,
                    backgroundColor: .clear,
                    borderColor: nil
                ),
                .highlighted: Button.StateStyle(
                    textColor: .primaryAction.withAlphaComponent(0.8),
                    backgroundColor: nil,
                    borderColor: nil
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: nil,
                    borderColor: nil
                ),
            ],
            margins: UIEdgeInsets(
                vertical: .spacingXS,
                horizontal: 0
            )
        )
    }

    static var callToAction: Button.Style {
        Button.Style(
            borderWidth: 0.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .white,
                    backgroundColor: .primaryAction,
                    borderColor: nil
                ),
                .highlighted: Button.StateStyle(
                    textColor: nil,
                    backgroundColor: .primaryAction.withAlphaComponent(0.8),
                    borderColor: nil
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: .secondaryBackground,
                    borderColor: nil
                )
            ]
        )
    }

    static var destructive: Button.Style {
        Button.Style(
            borderWidth: 0.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .white,
                    backgroundColor: .criticalAction,
                    borderColor: nil
                ),
                .highlighted: Button.StateStyle(
                    textColor: nil,
                    backgroundColor: .criticalAction.withAlphaComponent(0.8),
                    borderColor: nil
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: .secondaryBackground,
                    borderColor: nil
                )
            ]
        )
    }

    static var destructiveFlat: Button.Style {
        Button.Style(
            borderWidth: 0.0,
            stateStyles: [
                .normal: Button.StateStyle(
                    textColor: .criticalAction,
                    backgroundColor: .clear,
                    borderColor: nil
                ),
                .highlighted: Button.StateStyle(
                    textColor: .criticalAction.withAlphaComponent(0.8),
                    backgroundColor: nil,
                    borderColor: nil
                ),
                .disabled: Button.StateStyle(
                    textColor: .tertiaryText,
                    backgroundColor: nil,
                    borderColor: nil
                ),
            ]
        )
    }
}

extension UIControl.State: Hashable {}
