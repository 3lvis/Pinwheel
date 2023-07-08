import UIKit

public protocol FontProvider {
    var headline: UIFont { get }
    var headlineSemibold: UIFont { get }
    var headlineBold: UIFont { get }

    var body: UIFont { get }

    var subheadline: UIFont { get }
    var subheadlineSemibold: UIFont { get }
    var subheadlineBold: UIFont { get }

    var caption: UIFont { get }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}
