import SwiftUI
import UIKit

public enum UIPinButtonStyle {
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

public final class UIPinButton: UIControl {
    private let systemImage: String?
    private let font: PinTextStyle
    private let style: UIPinButtonStyle
    private var host: PinHostView<AnyView>!

    public var title: String? { didSet { reload() } }
    public var isLoading: Bool = false { didSet { reload() } }
    public override var isEnabled: Bool { didSet { reload() } }

    /// `addTarget(_:action:for: .touchUpInside)` also fires.
    public var onTap: (() -> Void)?

    public init(
        title: String? = nil,
        systemImage: String? = nil,
        font: PinTextStyle = .subtitleSemibold,
        style: UIPinButtonStyle = .primary
    ) {
        self.title = title
        self.systemImage = systemImage
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

    public func showActivityIndicator(_ shouldShow: Bool) {
        isLoading = shouldShow
    }

    private func reload() {
        host?.rootView = makeRootView()
    }

    private func makeRootView() -> AnyView {
        AnyView(
            PinButton(title, systemImage: systemImage) { [weak self] in
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
