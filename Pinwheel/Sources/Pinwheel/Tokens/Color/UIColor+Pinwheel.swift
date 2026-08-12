import UIKit

nonisolated extension UIColor {
    public class var primaryText: UIColor { themed { $0.primaryText } }
    public class var secondaryText: UIColor { themed { $0.secondaryText } }
    public class var tertiaryText: UIColor { themed { $0.tertiaryText } }
    public class var actionText: UIColor { themed { $0.actionText } }
    public class var criticalText: UIColor { themed { $0.criticalText } }

    public class var primaryBackground: UIColor { themed { $0.primaryBackground } }
    public class var secondaryBackground: UIColor { themed { $0.secondaryBackground } }
    public class var actionBackground: UIColor { themed { $0.actionBackground } }
    public class var criticalBackground: UIColor { themed { $0.criticalBackground } }

    private static func themed(_ token: @escaping @Sendable (ColorProvider) -> UIColor) -> UIColor {
        UIColor { traits in token(traits[PinwheelThemeTrait.self].colors) }
    }
}
