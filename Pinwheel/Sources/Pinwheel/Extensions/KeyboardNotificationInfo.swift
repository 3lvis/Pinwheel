import Foundation
import UIKit

public struct KeyboardNotificationInfo {
    public enum KeyboardAction {
        case willShow
        case willHide
    }

    public let animationOptions: UIView.AnimationOptions
    public let animationDuration: Double
    public let frameStart: CGRect?
    public let frameEnd: CGRect?
    public let action: KeyboardAction

    public init?(_ notification: Notification) {
        guard let keyboardAction = notification.keyboardNotificationAction, let userInfo = notification.userInfo else { return nil }
        action = keyboardAction

        if let animationCurve = userInfo[UIWindow.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationOptions = UIView.AnimationOptions(rawValue: animationCurve.uintValue)
        } else {
            animationOptions = []
        }

        animationDuration = (userInfo[UIWindow.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0
        frameStart = userInfo[UIWindow.keyboardFrameBeginUserInfoKey] as? CGRect
        frameEnd = userInfo[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect
    }

    /// Clamped to >= 0 so an iPad with an external keyboard (which would report a negative intersection) reads as no overlap.
    public func keyboardFrameEndIntersectHeight(inView view: UIView) -> CGFloat {
        // The Prefer Cross-Fade Transitions accessibility setting leaves frameEnd empty.
        guard let frameEnd = frameEnd, !frameEnd.isEmpty else { return 0 }
        let frameInWindow = view.convert(view.bounds, to: nil)
        let intersection = frameEnd.intersection(frameInWindow)
        let safeInsetBottom: CGFloat = view.safeAreaInsets.bottom

        let viewMaxY = frameInWindow.origin.y + frameInWindow.height
        let keyboardMaxY = frameEnd.origin.y + frameEnd.height
        let outOfBoundsHeight = max(0, viewMaxY - keyboardMaxY)

        return max(0, intersection.height + outOfBoundsHeight - safeInsetBottom)
    }
}

private extension Notification {
    var keyboardNotificationAction: KeyboardNotificationInfo.KeyboardAction? {
        switch self.name {
        case UIResponder.keyboardWillHideNotification:
            return .willHide
        case UIResponder.keyboardWillShowNotification:
            return .willShow
        default:
            return nil
        }
    }
}
