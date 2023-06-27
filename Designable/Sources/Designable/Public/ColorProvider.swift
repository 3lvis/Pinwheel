import UIKit

public protocol ColorProvider {
    var primaryText: UIColor { get }
    var secondaryText: UIColor { get }
    var tertiaryText: UIColor { get }

    var primaryAction: UIColor { get }
    var criticalAction: UIColor { get }

    var primaryBackground: UIColor { get }
    var secondaryBackground: UIColor { get }
    var tertiaryBackground: UIColor { get }
    var criticalBackground: UIColor { get }
}
