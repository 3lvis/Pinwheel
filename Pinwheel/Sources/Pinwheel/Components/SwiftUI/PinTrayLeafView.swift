import SwiftUI
import UIKit

@MainActor
final class PinTrayLeafView: UIView {
    private let hosting: UIHostingController<AnyView>

    init(showing leaf: AnyView, in parent: UIViewController) {
        hosting = UIHostingController(rootView: leaf)
        super.init(frame: .zero)

        backgroundColor = .clear
        hosting.view.backgroundColor = .clear
        hosting.safeAreaRegions = []
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        parent.addChild(hosting)
        addSubview(hosting.view)
        hosting.didMove(toParent: parent)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayLeafView is made in code") }

    // The tray's parts each take their content through `show`, and each writes a stored property of
    // its own. Written at the call site the chassis would reach two levels down, past the part into
    // what it hosts.
    // oida:disable:next no_single_use_void_functions
    func show(_ leaf: AnyView) {
        hosting.rootView = leaf
    }

    func height(fitting width: CGFloat) -> CGFloat {
        hosting.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    func detach() {
        hosting.willMove(toParent: nil)
        hosting.view.removeFromSuperview()
        hosting.removeFromParent()
    }
}
