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
    /// Bridges a UIKit `Tweak` to a SwiftUI `PinwheelTweak`, so a hosted
    /// `Tweakable` UIKit view's options appear in the SwiftUI playground's
    /// settings sheet. Returns nil for unknown `Tweak` kinds.
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

/// Backs a bridged `BoolTweak` with mutable state and forwards changes to the
/// UIKit tweak's action.
private final class PinwheelTweakBoolStore {
    private var isOn: Bool
    private let action: (Bool) -> Void

    init(_ tweak: BoolTweak) {
        self.isOn = tweak.isOn
        self.action = tweak.action
    }

    var binding: Binding<Bool> {
        Binding(
            get: { self.isOn },
            set: { newValue in
                self.isOn = newValue
                self.action(newValue)
            }
        )
    }
}

/// Hosts a UIKit view as a view controller's full-bounds content.
///
/// Used to embed `view:` catalog items in SwiftUI: a `UIViewControllerRepresentable`
/// is handed the full proposed size by SwiftUI, so the hosted view lays out at
/// full bounds — as it would in a real UIKit hierarchy. A bare
/// `UIViewRepresentable` instead sizes to the view's fitting size, which left
/// edge-pinned UIKit examples (e.g. the DNA examples, table-backed examples)
/// collapsed to content and pinned top-left in the catalog/preview.
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
