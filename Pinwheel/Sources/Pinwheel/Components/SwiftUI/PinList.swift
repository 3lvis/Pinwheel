import SwiftUI

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
            // No per-row id to key on; positional identity is stable because rows are a fixed value array per render.
            List(Array(rows.enumerated()), id: \.offset) { _, row in
                row.listRowBackground(Color.primaryBackground)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.primaryBackground)
        default:
            PinStateView(state, onAction: onRetry)
        }
    }
}

public extension PinList {
    struct Row: SwiftUI.View {
        private enum Kind {
            case text(subtitle: String?, detail: String?, chevron: Bool, enabled: Bool, action: (() -> Void)?)
            case toggle(subtitle: String?, enabled: Bool, isOn: Binding<Bool>)
        }

        private let title: String
        private let kind: Kind

        private init(title: String, kind: Kind) {
            self.title = title
            self.kind = kind
        }

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

        public static func toggle(_ title: String, subtitle: String? = nil, enabled: Bool = true, isOn: Binding<Bool>) -> Row {
            Row(title: title, kind: .toggle(subtitle: subtitle, enabled: enabled, isOn: isOn))
        }

        public var body: some SwiftUI.View {
            // Groups the row's captured children (its labels) into one Figma frame when the tree is
            // captured; a no-op when nothing reads the preference, so ordinary rendering is unaffected.
            rowContent.pinCapturedContainer(name: title)
        }

        @ViewBuilder
        private var rowContent: some SwiftUI.View {
            switch kind {
            case let .text(subtitle, detail, chevron, enabled, action):
                textRow(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action)
            case let .toggle(subtitle, enabled, isOn):
                // Label left, switch right — the switch is a separate rasterization marker so the
                // labels stay structured while the host photographs the native switch.
                HStack(spacing: .spacingS) {
                    labels(subtitle: subtitle, enabled: enabled)
                    Spacer()
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .disabled(!enabled)
                        .pinCapturedRasterized(name: "Switch")
                }
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
                        .foregroundStyle(.secondaryText)
                        .pinCapturedRasterized(name: "Chevron")
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
