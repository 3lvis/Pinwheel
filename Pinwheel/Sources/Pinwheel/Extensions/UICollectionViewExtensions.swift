import UIKit

extension UICollectionReusableView: PinReuseIdentifiable {}

public extension UICollectionView {
    func register(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass.self, forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    func register(_ cellClass: UICollectionReusableView.Type, ofKind kind: String) {
        register(
            cellClass.self,
            forSupplementaryViewOfKind: kind,
            withReuseIdentifier: cellClass.reuseIdentifier
        )
    }

    func registerNib(_ cellClass: UICollectionViewCell.Type, bundle: Bundle? = nil) {
        register(UINib(nibName: String(describing: cellClass), bundle: bundle), forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    func dequeue<T>(_ cellClass: T.Type, for indexPath: IndexPath) -> T where T: UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: cellClass.reuseIdentifier, for: indexPath) as? T else {
            preconditionFailure("\(cellClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return cell
    }

    func dequeue<T>(
        _ reusableSupplementaryViewClass: T.Type,
        for indexPath: IndexPath,
        ofKind kind: String
    ) -> T where T: UICollectionReusableView {
        let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: reusableSupplementaryViewClass.reuseIdentifier,
            for: indexPath
        )
        guard let supplementaryView = view as? T else {
            preconditionFailure("\(reusableSupplementaryViewClass.reuseIdentifier) is registered to a different class than \(T.self)")
        }
        return supplementaryView
    }
}
