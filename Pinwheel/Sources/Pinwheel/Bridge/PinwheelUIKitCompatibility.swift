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
            self.init(toggle.title, description: toggle.description, isOn: PinwheelTweakBoolStore(toggle).binding)
        } else {
            return nil
        }
    }
}

final class PinwheelTweakBoolStore {
    private var isOn: Bool
    private let action: (Bool) -> Void

    init(_ tweak: BoolTweak) {
        self.isOn = tweak.isOn
        self.action = tweak.action
    }

    // Forwarding kept separate from `binding` so it's unit-testable without
    // driving SwiftUI's Binding, which hangs in a hostless unit test.
    func set(_ newValue: Bool) {
        isOn = newValue
        action(newValue)
    }

    var binding: Binding<Bool> {
        Binding(get: { self.isOn }, set: { self.set($0) })
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
