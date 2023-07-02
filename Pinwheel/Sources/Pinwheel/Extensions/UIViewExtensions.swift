import UIKit

public extension UIView {
    convenience init(withAutoLayout autoLayout: Bool) {
        self.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autoLayout
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

@available(iOS 15.0, *)
public extension UIView {
    var windowSafeAreaInsets: UIEdgeInsets {
        return UIView.windowSafeAreaInsets
    }

    static var windowSafeAreaInsets: UIEdgeInsets {
        return UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last?.safeAreaInsets ?? .zero
    }
}
