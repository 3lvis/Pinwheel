import SwiftUI
import UIKit

@MainActor
final class PinTrayContentsView: UIView {
    private let titleBar: PinTrayLeafView
    private let body: PinTrayBodyView
    private let divider = UIView()

    var clearance: CGFloat {
        get { body.clearance }
        set { body.clearance = newValue }
    }

    init(titleBar: AnyView, content: AnyView, in parent: UIViewController, reporting to: PinTrayBodyCoordinating) {
        self.titleBar = PinTrayLeafView(showing: titleBar, in: parent)
        body = PinTrayBodyView(showing: content, in: parent, reporting: to)
        super.init(frame: .zero)

        divider.backgroundColor = .tertiaryText
        for view in [self.titleBar, divider, body] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            self.titleBar.topAnchor.constraint(equalTo: topAnchor),
            self.titleBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.topAnchor.constraint(equalTo: self.titleBar.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: trayContentMargin),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trayContentMargin),
            body.topAnchor.constraint(equalTo: divider.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor),
            body.trailingAnchor.constraint(equalTo: trailingAnchor),
            body.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayContentsView is made in code") }

    func show(titleBar leaf: AnyView, content: AnyView) {
        titleBar.show(leaf)
        body.show(content)
    }

    func height(fitting width: CGFloat) -> CGFloat {
        titleBar.height(fitting: width) + 1 + body.contentHeight(fitting: width)
    }

    func detach() {
        titleBar.detach()
        body.detach()
        removeFromSuperview()
    }
}
