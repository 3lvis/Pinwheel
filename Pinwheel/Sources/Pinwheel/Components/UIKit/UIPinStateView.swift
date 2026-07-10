import SwiftUI
import UIKit

public protocol UIPinStateViewDelegate: AnyObject {
    func stateViewDidSelectAction(_ stateView: UIPinStateView)
}

public enum UIPinStateViewState {
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

public final class UIPinStateView: UIView {
    public weak var delegate: UIPinStateViewDelegate?

    /// The `delegate` also fires.
    public var onAction: (() -> Void)?

    // Hides itself in `.loaded`, so consumers pinning it over content reveal the content underneath without managing alpha.
    public var state: UIPinStateViewState = .loaded {
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
