import SwiftUI

/// SwiftUI-native themed list with a built-in loading / empty / failed state —
/// the SwiftUI counterpart of `UIKitPinTableView`. `.loaded` renders the themed
/// rows; any other `PinState` renders a `PinStateView` overlay (reusing the same
/// state machine the UIKit table uses).
///
/// ```swift
/// PinList(state: phase, rows: [
///     .text("Only title"),
///     .text("Title", subtitle: "sub", detail: "Detail", chevron: true) { open() },
///     .text("Is disabled", enabled: false),
///     .toggle("Notifications", isOn: $on),
/// ], onRetry: retry)
/// ```
public struct PinList: SwiftUI.View {
    private let state: PinState
    private let rows: [Row]
    private let onRetry: () -> Void

    public init(state: PinState = .loaded, rows: [Row], onRetry: @escaping () -> Void = {}) {
        self.state = state
        self.rows = rows
        self.onRetry = onRetry
    }

    public var body: some SwiftUI.View {
        switch state {
        case .loaded:
            List(Array(rows.enumerated()), id: \.offset) { _, row in
                row.listRowBackground(PinwheelTheme.Colors.primaryBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(PinwheelTheme.Colors.primaryBackground)
        default:
            PinStateView(state, onAction: onRetry)
        }
    }
}

public extension PinList {
    /// A row in a `PinList`. Built with the `.text` / `.toggle` factories so the
    /// common case stays terse (defaults) while toggles carry a `Binding`.
    struct Row: SwiftUI.View {
        private enum Kind {
            case text(subtitle: String?, detail: String?, chevron: Bool, enabled: Bool, action: (() -> Void)?)
            case toggle(subtitle: String?, isOn: Binding<Bool>)
        }

        private let title: String
        private let kind: Kind

        private init(title: String, kind: Kind) {
            self.title = title
            self.kind = kind
        }

        /// A text row: title, optional subtitle, optional trailing detail, an
        /// optional chevron, and an optional tap `action`. `enabled: false` dims
        /// it and makes it non-interactive.
        public static func text(
            _ title: String,
            subtitle: String? = nil,
            detail: String? = nil,
            chevron: Bool = false,
            enabled: Bool = true,
            action: (() -> Void)? = nil
        ) -> Row {
            Row(title: title, kind: .text(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action))
        }

        /// A switch row bound to `isOn`.
        public static func toggle(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> Row {
            Row(title: title, kind: .toggle(subtitle: subtitle, isOn: isOn))
        }

        public var body: some SwiftUI.View {
            switch kind {
            case let .text(subtitle, detail, chevron, enabled, action):
                textRow(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action)
            case let .toggle(subtitle, isOn):
                Toggle(isOn: isOn) { labels(subtitle: subtitle, enabled: true) }
            }
        }

        private func labels(subtitle: String?, enabled: Bool) -> some SwiftUI.View {
            VStack(alignment: .leading, spacing: .spacingXXS) {
                PinLabel(title).color(enabled ? .primary : .secondary)
                if let subtitle {
                    PinLabel(subtitle).font(.caption).color(enabled ? .primary : .secondary)
                }
            }
        }

        @ViewBuilder
        private func textRow(
            subtitle: String?,
            detail: String?,
            chevron: Bool,
            enabled: Bool,
            action: (() -> Void)?
        ) -> some SwiftUI.View {
            let content = HStack(spacing: .spacingS) {
                labels(subtitle: subtitle, enabled: enabled)
                Spacer()
                if let detail {
                    PinLabel(detail).color(.secondary)
                }
                if chevron {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(PinwheelTheme.Colors.secondaryText)
                }
            }

            if let action {
                Button(action: action) { content }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
            } else {
                content
            }
        }
    }
}
