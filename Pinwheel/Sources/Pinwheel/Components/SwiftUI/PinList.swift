import SwiftUI

public struct PinList: SwiftUI.View {
    private let state: PinState
    private let rows: [Row]
    private let onRetry: () -> Void
    @Environment(\.pinCapturing) private var pinCapturing

    public init(state: PinState = .loaded, rows: [Row], onRetry: @escaping () -> Void = {}) {
        self.state = state
        self.rows = rows
        self.onRetry = onRetry
    }

    public var body: some SwiftUI.View {
        switch state {
        case .loaded:
            if pinCapturing {
                eagerRows
            } else {
                // No per-row id to key on; positional identity is stable because rows are a fixed value array per render.
                List(Array(rows.enumerated()), id: \.offset) { _, row in
                    row.listRowBackground(Color.primaryBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(.primaryBackground)
            }
        default:
            PinStateView(state, onAction: onRetry)
        }
    }

    private var eagerRows: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    row
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingS)
                    Divider()
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
            rowContent.pinCapturedContainer(
                name: captureTemplate,
                layout: PinCaptureLayout(axis: .row, spacing: .spacingS, spaceBetween: true)
            )
        }

        private var captureTemplate: String {
            switch kind {
            case let .text(subtitle, detail, chevron, _, _):
                var parts = ["Row"]
                if icon != nil { parts.append("icon") }
                if subtitle != nil { parts.append("subtitle") }
                if detail != nil { parts.append("detail") }
                if chevron { parts.append("chevron") }
                return parts.joined(separator: "-")
            case let .toggle(subtitle, _, isOn):
                var parts = ["Row", "toggle"]
                if icon != nil { parts.append("icon") }
                if subtitle != nil { parts.append("subtitle") }
                parts.append(isOn.wrappedValue ? "on" : "off")
                return parts.joined(separator: "-")
            }
        }

        @ViewBuilder
        private var rowContent: some SwiftUI.View {
            switch kind {
            case let .text(subtitle, detail, chevron, enabled, action):
                textRow(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action)
            case let .toggle(subtitle, enabled, isOn):
                HStack(spacing: .spacingS) {
                    if let icon { iconView(icon, enabled: enabled) }
                    labels(subtitle: subtitle, enabled: enabled)
                        .pinCapturedContainer(name: "Labels", layout: PinCaptureLayout(axis: .column, spacing: .spacingXXS, alignment: .leading))
                    Spacer()
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .disabled(!enabled)
                        // The switch draws taller than its frame and right-aligns, so the crop clips it; background-coloured padding keeps the whole control in bounds, invisible in Figma.
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS)
                        .pinCapturedRasterized(name: "Switch")
                }
            }
        }

        private func iconView(_ image: Image, enabled: Bool) -> some SwiftUI.View {
            image
                .foregroundStyle(enabled ? PinwheelTheme.Colors.actionText : PinwheelTheme.Colors.secondaryText)
                .frame(width: .spacingXL)
                .pinCapturedRasterized(name: "Icon")
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
                    .pinCapturedContainer(name: "Labels", layout: PinCaptureLayout(axis: .column, spacing: .spacingXXS, alignment: .leading))
                Spacer()
                if detail != nil || chevron {
                    HStack(spacing: .spacingS) {
                        if let detail {
                            PinLabel(detail).color(.secondary)
                        }
                        if chevron {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondaryText)
                                .pinCapturedRasterized(name: "Chevron")
                        }
                    }
                    .pinCapturedContainer(name: "Trailing", layout: PinCaptureLayout(axis: .row, spacing: .spacingS))
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
