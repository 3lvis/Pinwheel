import UIKit

public extension UITableViewCell {
    func setDefaultSelectedBackgound() {
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .secondaryBackground
        self.selectedBackgroundView = selectedBackgroundView
    }
}
