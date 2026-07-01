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
    }
}

extension FloatingButton.Style {
    static var `default`: FloatingButton.Style {
        FloatingButton.Style(
            tintColor: .actionText,
            titleColor: .tertiaryText,
            primaryBackgroundColor: .secondaryBackground,
            highlightedBackgroundColor: .tertiaryText,
            borderWidth: 0,
            borderColor: nil,
            badgeBackgroundColor: .actionText,
            badgeTextColor: .primaryBackground,
            badgeSize: 30,
            shadowColor: .black.withAlphaComponent(0.2),
            shadowOffset: CGSize(width: 0, height: 6),
            shadowRadius: 6
        )
    }
}
