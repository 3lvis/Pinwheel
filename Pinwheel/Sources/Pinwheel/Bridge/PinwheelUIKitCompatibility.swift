import SwiftUI
import UIKit

public struct PinwheelUIKitViewController: UIViewControllerRepresentable {
    private let makeViewController: () -> UIViewController

    public init(makeViewController: @escaping () -> UIViewController) {
        self.makeViewController = makeViewController
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        return makeViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

extension PinwheelTweak {
    /// Returns nil for unknown `Tweak` kinds.
    init?(_ tweak: Tweak) {
        if let text = tweak as? TextTweak {
            self.init(text.title, description: text.description, action: text.action)
        } else if let toggle = tweak as? BoolTweak {
            // Back the toggle with captured locals, not a class: a @MainActor class
            // (the package's default isolation) has an isolated deinit that hops to
            // the main actor on release and deadlocks when ARC frees it off-main
            // (e.g. XCTest teardown on a headless CI runner).
            let action = toggle.action
            var isOn = toggle.isOn
            self.init(
                toggle.title,
                description: toggle.description,
                isOn: Binding(get: { isOn }, set: { isOn = $0; action($0) })
            )
        } else {
            return nil
        }
    }
}

/// Hosts a UIKit view at full bounds. Wrapping in a `UIViewControllerRepresentable`
/// (not a bare `UIViewRepresentable`) is deliberate: SwiftUI hands a controller the
/// full proposed size, whereas a `UIViewRepresentable` sizes to the fitting size and
/// collapses edge-pinned examples (Tokens, table-backed) to the top-left.
final class PinwheelUIKitContainerViewController: UIViewController {
    private let makeContent: () -> UIView

    init(makeContent: @escaping () -> UIView) {
        self.makeContent = makeContent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let content = makeContent()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
