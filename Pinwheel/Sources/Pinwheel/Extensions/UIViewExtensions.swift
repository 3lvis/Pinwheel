import UIKit

public extension UIView {
    convenience init(withAutoLayout autoLayout: Bool) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autoLayout
    }

    var parentViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }

    func resetDropShadow() {
        layer.shadowColor = nil
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
    }

    func dropShadow(color: UIColor, opacity: Float = 0.5, offset: CGSize = CGSize.zero, radius: CGFloat = 10.0) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.rasterizationScale = UIScreen.main.scale
    }
}

extension UIViewController {
    /// Replaces the deprecated `setOverrideTraitCollection(_:forChild:)`; call on the child whose traits to override.
    func applyDeviceTraitOverrides(_ traits: UITraitCollection) {
        traitOverrides.horizontalSizeClass = traits.horizontalSizeClass
        traitOverrides.verticalSizeClass = traits.verticalSizeClass
        traitOverrides.userInterfaceIdiom = traits.userInterfaceIdiom
    }
}

@available(iOS 15.0, *)
public extension UIView {
    var windowSafeAreaInsets: UIEdgeInsets {
        return UIView.windowSafeAreaInsets
    }

    static var windowSafeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last?.safeAreaInsets ?? .zero
    }
}
