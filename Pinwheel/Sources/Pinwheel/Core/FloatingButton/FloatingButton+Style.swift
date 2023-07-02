import UIKit

extension FloatingButton {
    struct Style: Equatable {
        let tintColor: UIColor
        let titleColor: UIColor
        let primaryBackgroundColor: UIColor
        let highlightedBackgroundColor: UIColor
        let borderWidth: CGFloat
        let borderColor: UIColor?
        let badgeBackgroundColor: UIColor
        let badgeTextColor: UIColor
        let badgeSize: CGFloat
        let shadowColor: UIColor
        let shadowOffset: CGSize
        let shadowRadius: CGFloat

        init(
            tintColor: UIColor,
            titleColor: UIColor,
            primaryBackgroundColor: UIColor,
            highlightedBackgroundColor: UIColor,
            borderWidth: CGFloat,
            borderColor: UIColor?,
            badgeBackgroundColor: UIColor,
            badgeTextColor: UIColor,
            badgeSize: CGFloat,
            shadowColor: UIColor,
            shadowOffset: CGSize,
            shadowRadius: CGFloat
        ) {
            self.tintColor = tintColor
            self.titleColor = titleColor
            self.primaryBackgroundColor = primaryBackgroundColor
            self.highlightedBackgroundColor = highlightedBackgroundColor
            self.borderWidth = borderWidth
            self.borderColor = borderColor
            self.badgeBackgroundColor = badgeBackgroundColor
            self.badgeTextColor = badgeTextColor
            self.badgeSize = badgeSize
            self.shadowColor = shadowColor
            self.shadowOffset = shadowOffset
            self.shadowRadius = shadowRadius
        }

        /// Given an existing style, this helps to create a new one overriding some of the values of the original style
        /// This method is intended for styles for concrete cases rather than default styles
        public func overrideStyle(
            tintColor: UIColor? = nil,
            titleColor: UIColor? = nil,
            primaryBackgroundColor: UIColor? = nil,
            highlightedBackgroundColor: UIColor? = nil,
            borderWidth: CGFloat? = nil,
            borderColor: UIColor? = nil,
            badgeBackgroundColor: UIColor? = nil,
            badgeTextColor: UIColor? = nil,
            badgeSize: CGFloat? = nil,
            shadowColor: UIColor? = nil,
            shadowOffset: CGSize? = nil,
            shadowRadius: CGFloat? = nil
        ) -> Style {
            Style(
                tintColor: tintColor ?? self.tintColor,
                titleColor: titleColor ?? self.titleColor,
                primaryBackgroundColor: primaryBackgroundColor ?? self.primaryBackgroundColor,
                highlightedBackgroundColor: highlightedBackgroundColor ?? self.highlightedBackgroundColor,
                borderWidth: borderWidth ?? self.borderWidth,
                borderColor: borderColor ?? self.borderColor,
                badgeBackgroundColor: badgeBackgroundColor ?? self.badgeBackgroundColor,
                badgeTextColor: badgeTextColor ?? self.badgeTextColor,
                badgeSize: badgeSize ?? self.badgeSize,
                shadowColor: shadowColor ?? self.shadowColor,
                shadowOffset: shadowOffset ?? self.shadowOffset,
                shadowRadius: shadowRadius ?? self.shadowRadius
            )
        }
    }
}

// MARK: - Styles
extension FloatingButton.Style {
    static var `default`: FloatingButton.Style {
        FloatingButton.Style(
            tintColor: .primaryAction,
            titleColor: .tertiaryText,
            primaryBackgroundColor: .secondaryBackground,
            highlightedBackgroundColor: .tertiaryText,
            borderWidth: 0,
            borderColor: nil,
            badgeBackgroundColor: .primaryAction,
            badgeTextColor: .primaryBackground,
            badgeSize: 30,
            shadowColor: .black.withAlphaComponent(0.2),
            shadowOffset: CGSize(width: 0, height: 6),
            shadowRadius: 6
        )
    }
}
