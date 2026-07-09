import UIKit
import Pinwheel

// A plain UICollectionView (no Pinwheel wrapper): the capture engine already force-realizes and walks
// collection cells like a table, so this is a "how it could work" demo, not a shipped component.
class UIKitPinCollectionViewDemo: UIKitPinView {
    private let items: [(title: String, color: UIColor)] = (1...8).map { index in
        let palette: [UIColor] = [.actionBackground, .secondaryBackground, .criticalBackground]
        return ("Item \(index)", palette[(index - 1) % palette.count])
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = .spacingM
        layout.minimumLineSpacing = .spacingM
        layout.sectionInset = UIEdgeInsets(top: .spacingL, left: .spacingL, bottom: .spacingL, right: .spacingL)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(PinCardCell.self, forCellWithReuseIdentifier: PinCardCell.reuseIdentifier)
        return view
    }()

    override func setup() {
        addSubview(collectionView)
        collectionView.fillInSuperview()
    }
}

extension UIKitPinCollectionViewDemo: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PinCardCell.reuseIdentifier, for: indexPath) as! PinCardCell
        let item = items[indexPath.item]
        cell.configure(title: item.title, color: item.color)
        return cell
    }
}

extension UIKitPinCollectionViewDemo: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let available = collectionView.bounds.width - .spacingL * 2 - .spacingM * (columns - 1)
        return CGSize(width: floor(available / columns), height: 96)
    }
}

private final class PinCardCell: UICollectionViewCell {
    static let reuseIdentifier = "PinCardCell"
    private let label = UIKitPinLabel(font: .body)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = .radiusM
        contentView.layer.masksToBounds = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: .spacingS),
            label.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -.spacingS)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, color: UIColor) {
        contentView.backgroundColor = color
        label.text = title
        label.textColor = .primaryText
    }
}
