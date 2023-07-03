import UIKit

final class NotchView: View {
    var isHandleHidden: Bool {
        get { handleView.isHidden }
        set { handleView.isHidden = newValue }
    }

    private let handleView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = .tertiaryText
        view.layer.cornerRadius = 2
        return view
    }()

    override func setup() {
        addSubview(handleView)

        let notchSize = CGSize(width: 25, height: 4)
        NSLayoutConstraint.activate([
            handleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            handleView.heightAnchor.constraint(equalToConstant: notchSize.height),
            handleView.widthAnchor.constraint(equalToConstant: notchSize.width)
        ])
    }
}
