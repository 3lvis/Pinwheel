import SwiftUI

/// `.loaded` renders nothing, so this can sit as an overlay that reveals the underlying content once loaded.
public struct PinStateView: SwiftUI.View {
    private let state: PinState
    private let onAction: () -> Void

    public init(_ state: PinState, onAction: @escaping () -> Void = {}) {
        self.state = state
        self.onAction = onAction
    }

    public var body: some SwiftUI.View {
        switch state {
        case .loaded:
            SwiftUI.Color.clear
        case .loading(let title, let subtitle):
            placeholder(title: title, subtitle: subtitle, showsSpinner: true, actionTitle: nil)
        case .empty(let title, let subtitle):
            placeholder(title: title, subtitle: subtitle, showsSpinner: false, actionTitle: nil)
        case .failed(let title, let subtitle, let actionTitle):
            placeholder(title: title, subtitle: subtitle, showsSpinner: false, actionTitle: actionTitle)
        }
    }

    private func placeholder(
        title: String,
        subtitle: String,
        showsSpinner: Bool,
        actionTitle: String?
    ) -> some SwiftUI.View {
        VStack(spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                if showsSpinner {
                    ProgressView()
                }

                PinLabel(title).font(.subtitle)
            }

            PinLabel(subtitle).color(.secondary)

            if let actionTitle {
                PinButton(actionTitle, action: onAction)
                    .style(.secondary)
                    .padding(.top, .spacingM)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacingL)
        .frame(maxWidth: .infinity)
    }
}
