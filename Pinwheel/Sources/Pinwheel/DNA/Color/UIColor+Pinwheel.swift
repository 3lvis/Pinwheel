import UIKit

// MARK: - Semantic colors, dark mode compatible
extension UIColor {
    public class var primaryText: UIColor { Config.colorProvider.primaryText }
    public class var secondaryText: UIColor { Config.colorProvider.secondaryText }
    public class var tertiaryText: UIColor { Config.colorProvider.tertiaryText }
    public class var actionText: UIColor { Config.colorProvider.actionText }
    public class var criticalText: UIColor { Config.colorProvider.criticalText }

    public class var primaryBackground: UIColor { Config.colorProvider.primaryBackground }
    public class var secondaryBackground: UIColor { Config.colorProvider.secondaryBackground }
    public class var actionBackground: UIColor { Config.colorProvider.actionBackground }
    public class var criticalBackground: UIColor { Config.colorProvider.criticalBackground }
}
