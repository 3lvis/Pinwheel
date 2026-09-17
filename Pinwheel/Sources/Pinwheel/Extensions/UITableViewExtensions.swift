import UIKit

extension UITableViewCell: PinReuseIdentifiable {}

extension UITableViewHeaderFooterView: PinReuseIdentifiable {}

extension UITableView {
    public func register(_ cellClass: UITableViewCell.Type) {
        register(cellClass.self, forCellReuseIdentifier: cellClass.reuseIdentifier)
    }

    public func register(_ headerFooterClass: UITableViewHeaderFooterView.Type) {
        register(headerFooterClass.self, forHeaderFooterViewReuseIdentifier: headerFooterClass.reuseIdentifier)
    }

    public func registerNib(_ cellClass: UITableViewCell.Type, bundle: Bundle? = nil) {
        register(UINib(nibName: String(describing: cellClass), bundle: bundle), forCellReuseIdentifier: cellClass.reuseIdentifier)
    }

    public func dequeue<T>(_ cellClass: T.Type, for indexPath: IndexPath) -> T where T: UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: cellClass.reuseIdentifier, for: indexPath) as? T else {
            preconditionFailure("\(cellClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return cell
    }

    public func dequeue<T>(_ headerFooterClass: T.Type) -> T where T: UITableViewHeaderFooterView {
        guard let headerFooter = dequeueReusableHeaderFooterView(withIdentifier: headerFooterClass.reuseIdentifier) as? T else {
            preconditionFailure("\(headerFooterClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return headerFooter
    }

    public func stopScrolling() {
        setContentOffset(contentOffset, animated: false)
    }
}
