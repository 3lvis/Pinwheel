import SwiftUI
import UIKit

public protocol UIKitPinStateViewDelegate: AnyObject {
    func stateViewDidSelectAction(_ stateView: UIKitPinStateView)
}

/// UIKit-facing state, mapped onto the SwiftUI `PinState`.
public enum UIKitPinStateViewState {
    case loading(title: String, subtitle: String)
    case loaded
    case empty(title: String, subtitle: String)
    case failed(title: String, subtitle: String, actionTitle: String)

    var pinState: PinState {
        switch self {
        case .loading(let title, let subtitle):
            return .loading(title: title, subtitle: subtitle)
        case .loaded:
            return .loaded
        case .empty(let title, let subtitle):
            return .empty(title: title, subtitle: subtitle)
        case .failed(let title, let subtitle, let actionTitle):
            return .failed(title: title, subtitle: subtitle, actionTitle: actionTitle)
        }
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}

/// UIKit-friendly host over the SwiftUI `PinStateView`. There is a single state
/// view implementation — the SwiftUI `PinStateView` — and this is a thin shell
/// that gives a hybrid UIKit app the imperative ergonomics it expects (`state`
/// mutation and a delegate/closure action callback), so no SwiftUI knowledge is
/// needed at the call site.
public final class UIKitPinStateView: UIView {
    public weak var delegate: UIKitPinStateViewDelegate?

    /// Modern action handler for the failed-state button. The `delegate` also fires.
    public var onAction: (() -> Void)?

    // The view hides itself in `.loaded` (mirroring the old overlay behavior),
    // so consumers that pin it over content — e.g. UIKitPinTableView — reveal
    // the content underneath without managing the overlay's alpha themselves.
    public var state: UIKitPinStateViewState = .loaded {
        didSet {
            alpha = state.isLoaded ? 0 : 1
            reload()
        }
    }

    private var host: PinHostView<PinStateView>!

    public init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        alpha = state.isLoaded ? 0 : 1

        host = PinHostView(rootView: makeRootView())
        addSubview(host)
        // Hugs its content and centers vertically, matching the placeholder's
        // centered layout when pinned over content (e.g. a table's overlay).
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.centerYAnchor.constraint(equalTo: centerYAnchor),
            host.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            host.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reload() {
        host?.rootView = makeRootView()
    }

    private func makeRootView() -> PinStateView {
        PinStateView(state.pinState) { [weak self] in
            guard let self else { return }
            self.delegate?.stateViewDidSelectAction(self)
            self.onAction?()
        }
    }
}
