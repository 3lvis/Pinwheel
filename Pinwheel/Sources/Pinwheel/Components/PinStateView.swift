import SwiftUI

/// SwiftUI-native counterpart of the UIKit state view. Renders a centered
/// loading / empty / failed placeholder; `.loaded` renders nothing, so it can
/// sit as an overlay that reveals the underlying content once loaded.
public struct PinStateView: SwiftUI.View {
    public enum State: Equatable {
        case loading(title: String, subtitle: String)
        case loaded
        case empty(title: String, subtitle: String)
        case failed(title: String, subtitle: String, actionTitle: String)
    }

    private let state: State
    private let onAction: () -> Void

    public init(_ state: State, onAction: @escaping () -> Void = {}) {
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

                Text(title)
                    .font(PinwheelTheme.Typography.subtitle)
                    .foregroundStyle(PinwheelTheme.Colors.primaryText)
            }

            Text(subtitle)
                .font(PinwheelTheme.Typography.body)
                .foregroundStyle(PinwheelTheme.Colors.secondaryText)

            if let actionTitle {
                PinButton(actionTitle, style: .secondary, action: onAction)
                    .padding(.top, .spacingM)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacingL)
        .frame(maxWidth: .infinity)
    }
}
