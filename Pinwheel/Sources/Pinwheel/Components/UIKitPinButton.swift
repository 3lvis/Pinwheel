import SwiftUI
import UIKit

/// UIKit-facing style for `UIKitPinButton`, mapped onto the SwiftUI `PinButton.Style`.
public enum UIKitPinButtonStyle {
    case primary
    case secondary
    case tertiary
    case custom(textColor: UIColor, backgroundColor: UIColor)

    var pinStyle: PinButton.Style {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .tertiary:
            return .tertiary
        case .custom(let textColor, let backgroundColor):
            return .custom(
                text: SwiftUI.Color(uiColor: textColor),
                background: SwiftUI.Color(uiColor: backgroundColor)
            )
        }
    }
}

/// UIKit-friendly host over the SwiftUI `PinButton`. There is a single button
/// implementation — the SwiftUI `PinButton` — and this is a thin shell that gives
/// a hybrid UIKit app the imperative ergonomics it expects (title / isEnabled /
/// isLoading mutation and target-action), so no SwiftUI knowledge is needed at the
/// call site.
public final class UIKitPinButton: UIControl {
    private let symbol: String?
    private let font: PinLabel.Style
    private let style: UIKitPinButtonStyle
    private var host: PinHostView<AnyView>!

    public var title: String? { didSet { reload() } }
    public var isLoading: Bool = false { didSet { reload() } }
    public override var isEnabled: Bool { didSet { reload() } }

    /// Modern tap handler. `addTarget(_:action:for: .touchUpInside)` also works.
    public var onTap: (() -> Void)?

    public init(
        title: String? = nil,
        symbol: String? = nil,
        font: PinLabel.Style = .subtitleSemibold,
        style: UIKitPinButtonStyle = .primary
    ) {
        self.title = title
        self.symbol = symbol
        self.font = font
        self.style = style
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        host = PinHostView(rootView: makeRootView())
        addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Compatibility with the old UIKit API.
    public func showActivityIndicator(_ shouldShow: Bool) {
        isLoading = shouldShow
    }

    private func reload() {
        host?.rootView = makeRootView()
    }

    private func makeRootView() -> AnyView {
        AnyView(
            PinButton(title, systemImage: symbol) { [weak self] in
                guard let self else { return }
                self.sendActions(for: .touchUpInside)
                self.onTap?()
            }
            .font(font)
            .style(style.pinStyle)
            .loading(isLoading)
            .disabled(!isEnabled)
        )
    }
}
