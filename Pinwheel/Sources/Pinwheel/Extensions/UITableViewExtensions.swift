import UIKit

extension UITableViewCell: PinReuseIdentifiable {}

extension UITableViewHeaderFooterView: PinReuseIdentifiable {}

public extension UITableView {
    func register(_ cellClass: UITableViewCell.Type) {
        register(cellClass.self, forCellReuseIdentifier: cellClass.reuseIdentifier)
    }

    func register(_ headerFooterClass: UITableViewHeaderFooterView.Type) {
        register(headerFooterClass.self, forHeaderFooterViewReuseIdentifier: headerFooterClass.reuseIdentifier)
    }

    func registerNib(_ cellClass: UITableViewCell.Type, bundle: Bundle? = nil) {
        register(UINib(nibName: String(describing: cellClass), bundle: bundle), forCellReuseIdentifier: cellClass.reuseIdentifier)
    }

    func dequeue<T>(_ cellClass: T.Type, for indexPath: IndexPath) -> T where T: UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: cellClass.reuseIdentifier, for: indexPath) as? T else {
            preconditionFailure("\(cellClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return cell
    }

    func dequeue<T>(_ headerFooterClass: T.Type) -> T where T: UITableViewHeaderFooterView {
        guard let headerFooter = dequeueReusableHeaderFooterView(withIdentifier: headerFooterClass.reuseIdentifier) as? T else {
            preconditionFailure("\(headerFooterClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return headerFooter
    }

    func stopScrolling() {
        setContentOffset(contentOffset, animated: false)
    }
}
