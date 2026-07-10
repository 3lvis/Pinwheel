import UIKit
import Pinwheel

class CollectionViewGridDemo: UIPinView {
    private let metrics = ["Revenue", "Orders", "Users", "Refunds"]
    private let tags = ["New", "Sale", "Popular", "Limited"]

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
        view.register(MetricCardCell.self, forCellWithReuseIdentifier: MetricCardCell.reuseIdentifier)
        view.register(TagCardCell.self, forCellWithReuseIdentifier: TagCardCell.reuseIdentifier)
        return view
    }()

    override func setup() {
        addSubview(collectionView)
        collectionView.fillInSuperview()
    }
}

extension CollectionViewGridDemo: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? metrics.count : tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MetricCardCell.reuseIdentifier, for: indexPath) as! MetricCardCell
            cell.configure(title: metrics[indexPath.item])
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCardCell.reuseIdentifier, for: indexPath) as! TagCardCell
        cell.configure(title: tags[indexPath.item])
        return cell
    }
}

extension CollectionViewGridDemo: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 2
        let available = collectionView.bounds.width - .spacingL * 2 - .spacingM * (columns - 1)
        let width = floor(available / columns)
        return CGSize(width: width, height: indexPath.section == 0 ? 96 : 60)
    }
}

private final class MetricCardCell: UICollectionViewCell {
    static let reuseIdentifier = "MetricCardCell"
    private let label = UIPinLabel(font: .body)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .actionBackground
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

    func configure(title: String) { label.text = title }
}

private final class TagCardCell: UICollectionViewCell {
    static let reuseIdentifier = "TagCardCell"
    private let label = UIPinLabel(font: .caption)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondaryBackground
        contentView.layer.cornerRadius = .radiusL
        contentView.layer.masksToBounds = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String) { label.text = title }
}
