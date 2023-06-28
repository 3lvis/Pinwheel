import UIKit

public protocol ColorProvider {
    var primaryText: UIColor { get }
    var secondaryText: UIColor { get }
    var tertiaryText: UIColor { get }

    var primaryBackground: UIColor { get }
    var secondaryBackground: UIColor { get }

    var primaryAction: UIColor { get }
    var activeBackground: UIColor { get }
    var criticalAction: UIColor { get }
    var criticalBackground: UIColor { get }
}
