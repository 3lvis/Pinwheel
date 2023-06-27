import UIKit

public protocol FontProvider {
    var body: UIFont { get }
    var bodyStrong: UIFont { get }

    var caption: UIFont { get }
    var captionStrong: UIFont { get }

    var detail: UIFont { get }
    var detailStrong: UIFont { get }

    func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont
}
