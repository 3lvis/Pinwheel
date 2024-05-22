import UIKit

public protocol ColorProvider {
    var primaryText: UIColor { get }
    var secondaryText: UIColor { get }
    var tertiaryText: UIColor { get }
    var actionText: UIColor { get }
    var criticalText: UIColor { get }

    var primaryBackground: UIColor { get }
    var secondaryBackground: UIColor { get }
    var actionBackground: UIColor { get }
    var criticalBackground: UIColor { get }
}
