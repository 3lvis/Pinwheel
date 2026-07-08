import UIKit

public protocol FontProvider {
    var title: UIFont { get }
    var titleSemibold: UIFont { get }
    var subtitle: UIFont { get }
    var subtitleSemibold: UIFont { get }
    var body: UIFont { get }
    var bodySemibold: UIFont { get }
    var footnote: UIFont { get }
    var footnoteSemibold: UIFont { get }
    var caption: UIFont { get }
    var captionSemibold: UIFont { get }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}

// Semibold variants default to the regular size at semibold weight, so an existing provider gets them
// for free (and can still override any one).
public extension FontProvider {
    var titleSemibold: UIFont { font(ofSize: 23, weight: .semibold).scaledFont(forTextStyle: .headline) }
    var bodySemibold: UIFont { font(ofSize: 17, weight: .semibold).scaledFont(forTextStyle: .body) }
    var footnoteSemibold: UIFont { font(ofSize: 13, weight: .semibold).scaledFont(forTextStyle: .footnote) }
    var captionSemibold: UIFont { font(ofSize: 11, weight: .semibold).scaledFont(forTextStyle: .caption1) }
}
