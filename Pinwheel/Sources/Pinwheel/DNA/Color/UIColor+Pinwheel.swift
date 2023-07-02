import UIKit

// MARK: - Semantic colors, dark mode compatible
extension UIColor {
    public class var primaryText: UIColor { Config.colorProvider.primaryText }
    public class var secondaryText: UIColor { Config.colorProvider.secondaryText }
    public class var tertiaryText: UIColor { Config.colorProvider.tertiaryText }

    public class var primaryBackground: UIColor { Config.colorProvider.primaryBackground }
    public class var secondaryBackground: UIColor { Config.colorProvider.secondaryBackground }

    public class var primaryAction: UIColor { Config.colorProvider.primaryAction }
    public class var activeBackground: UIColor { Config.colorProvider.activeBackground }
    public class var criticalAction: UIColor { Config.colorProvider.criticalAction }
    public class var criticalBackground: UIColor { Config.colorProvider.criticalBackground }
}
