import UIKit

public extension UIEdgeInsets {
    init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.init(top: top, left: leading, bottom: bottom, right: trailing)
    }

    var leading: CGFloat {
        return left
    }

    var trailing: CGFloat {
        return right
    }
}
