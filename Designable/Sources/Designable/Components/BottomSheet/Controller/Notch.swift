import UIKit

final class Notch: UIView {
    var isHandleHidden: Bool {
        get { handle.isHidden }
        set { handle.isHidden = newValue }
    }

    // MARK: - private properties

    private let notchSize = CGSize(width: 25, height: 4)
    private let handle: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = .tertiaryText
        view.layer.cornerRadius = 2
        return view
    }()

    // MARK: - Init
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .primaryBackground
        addSubview(handle)

        NSLayoutConstraint.activate([
            handle.centerXAnchor.constraint(equalTo: centerXAnchor),
            handle.centerYAnchor.constraint(equalTo: centerYAnchor),
            handle.heightAnchor.constraint(equalToConstant: notchSize.height),
            handle.widthAnchor.constraint(equalToConstant: notchSize.width)
        ])
    }
}
