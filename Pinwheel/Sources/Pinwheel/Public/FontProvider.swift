import UIKit

public protocol FontProvider {
    var title: UIFont { get }
    var subtitle: UIFont { get }
    var body: UIFont { get }
    var bodySemibold: UIFont { get }
    var footnote: UIFont { get }
    var caption: UIFont { get }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}
