import SwiftUI

public struct PinList: SwiftUI.View {
    private let state: PinState
    private let rows: [Row]
    private let onRetry: () -> Void
    // A UIKit-backed `List` hides its rows behind per-cell hosting views the capture can't read, so under
    // capture PinList renders the same rows in a pure-SwiftUI stack instead. Same `Row` in both — 1:1 cells.
    @Environment(\.pinCapturing) private var capturing

    public init(state: PinState = .loaded, rows: [Row], onRetry: @escaping () -> Void = {}) {
        self.state = state
        self.rows = rows
        self.onRetry = onRetry
    }

    public var body: some SwiftUI.View {
        switch state {
        case .loaded:
            if capturing { capturableStack } else { productionList }
        default:
            PinStateView(state, onAction: onRetry)
        }
    }

    private var productionList: some SwiftUI.View {
        List {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                row
                    .listRowInsets(EdgeInsets(top: .spacingS, leading: .spacingM, bottom: .spacingS, trailing: .spacingM))
                    .listRowBackground(PinwheelTheme.Colors.primaryBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.primaryBackground)
    }

    // No per-row id to key on; positional identity is stable because rows are a fixed value array per render.
    private var capturableStack: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    row
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingS)
                    if index < rows.count - 1 {
                        Divider().padding(.leading, .spacingM)
                    }
                }
            }
        }
        .background(.primaryBackground)
    }
}

public extension PinList {
    struct Row: SwiftUI.View {
        private enum Kind {
            case text(subtitle: String?, detail: String?, chevron: Bool, enabled: Bool, action: (() -> Void)?)
            case toggle(subtitle: String?, enabled: Bool, isOn: Binding<Bool>)
        }

        private let title: String
        private let icon: Image?
        private let kind: Kind

        private init(title: String, icon: Image?, kind: Kind) {
            self.title = title
            self.icon = icon
            self.kind = kind
        }

        public static func text(
            _ title: String,
            icon: Image? = nil,
            subtitle: String? = nil,
            detail: String? = nil,
            chevron: Bool = false,
            enabled: Bool = true,
            action: (() -> Void)? = nil
        ) -> Row {
            Row(title: title, icon: icon, kind: .text(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action))
        }

        public static func toggle(_ title: String, icon: Image? = nil, subtitle: String? = nil, enabled: Bool = true, isOn: Binding<Bool>) -> Row {
            Row(title: title, icon: icon, kind: .toggle(subtitle: subtitle, enabled: enabled, isOn: isOn))
        }

        public var body: some SwiftUI.View {
            switch kind {
            case let .text(subtitle, detail, chevron, enabled, action):
                textRow(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action)
            case let .toggle(subtitle, enabled, isOn):
                Toggle(isOn: isOn) {
                    HStack(spacing: .spacingS) {
                        if let icon { iconView(icon, enabled: enabled) }
                        labels(subtitle: subtitle, enabled: enabled)
                    }
                }
                .disabled(!enabled)
            }
        }

        private func iconView(_ image: Image, enabled: Bool) -> some SwiftUI.View {
            image
                .foregroundStyle(enabled ? PinwheelTheme.Colors.actionText : PinwheelTheme.Colors.secondaryText)
                .frame(width: .spacingXL)
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
                if let icon { iconView(icon, enabled: enabled) }
                labels(subtitle: subtitle, enabled: enabled)
                Spacer()
                if let detail {
                    PinLabel(detail).color(.secondary)
                }
                if chevron {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondaryText)
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
