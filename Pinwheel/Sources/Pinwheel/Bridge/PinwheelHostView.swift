import SwiftUI
import UIKit

/// The hosting controller is re-parented to the nearest view controller on window move, so safe-area,
/// trait and environment propagation reach the hosted component.
public final class PinHostView<Content: SwiftUI.View>: UIView {
    private let hostingController: UIHostingController<Content>

    public init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        hostingController.sizingOptions = .intrinsicContentSize
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public convenience init(@ViewBuilder rootView: () -> Content) {
        self.init(rootView: rootView())
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var rootView: Content {
        get { hostingController.rootView }
        set { hostingController.rootView = newValue }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            if let parent = parentViewController, hostingController.parent !== parent {
                parent.addChild(hostingController)
                hostingController.didMove(toParent: parent)
            }
        } else if hostingController.parent != nil {
            hostingController.willMove(toParent: nil)
            hostingController.removeFromParent()
        }
    }
}
