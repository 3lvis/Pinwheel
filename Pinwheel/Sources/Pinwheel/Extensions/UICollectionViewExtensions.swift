import UIKit

extension UICollectionReusableView: ReuseIdentifiable {}

public extension UICollectionView {
    func register(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass.self, forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    func register(_ cellClass: UICollectionReusableView.Type, ofKind kind: String) {
        register(cellClass.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: cellClass.reuseIdentifier)
    }

    func registerNib(_ cellClass: UICollectionViewCell.Type, bundle: Bundle? = nil) {
        register(UINib(nibName: String(describing: cellClass), bundle: bundle), forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    func dequeue<T>(_ cellClass: T.Type, for indexPath: IndexPath) -> T where T: UICollectionViewCell {
        return dequeueReusableCell(withReuseIdentifier: cellClass.reuseIdentifier, for: indexPath) as! T
    }

    func dequeue<T>(_ reusableSupplementaryViewClass: T.Type, for indexPath: IndexPath, ofKind kind: String) -> T where T: UICollectionReusableView {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reusableSupplementaryViewClass.reuseIdentifier, for: indexPath) as! T
    }
}
