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
        private let leading: AnyView?
        private let kind: Kind

        private init(title: String, leading: AnyView?, kind: Kind) {
            self.title = title
            self.leading = leading
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
            Row(title: title, leading: nil, kind: .text(subtitle: subtitle, detail: detail, chevron: chevron, enabled: enabled, action: action))
        }

        public static func toggle(_ title: String, subtitle: String? = nil, enabled: Bool = true, isOn: Binding<Bool>) -> Row {
            Row(title: title, leading: nil, kind: .toggle(subtitle: subtitle, enabled: enabled, isOn: isOn))
        }

        /// A leading accessory (any view — an SF Symbol you tint, your own asset `Image`, an avatar).
        /// The caller owns its color and content; the row frames it to a consistent width.
        public func leading(@ViewBuilder _ view: () -> some SwiftUI.View) -> Row {
            Row(title: title, leading: AnyView(view()), kind: kind)
        }

        public var body: some SwiftUI.View {
            // Capture name is the row's *structure*, so identical rows reuse one Figma component; a
            // no-op when nothing reads the preference, so ordinary rendering is unaffected.
            rowContent.pinCapturedContainer(
                name: captureTemplate,
                layout: PinCaptureLayout(axis: .row, spacing: .spacingS, spaceBetween: true)
            )
        }

        private var captureTemplate: String {
            switch kind {
            case let .text(subtitle, detail, chevron, _, _):
                var parts = ["Row"]
                if leading != nil { parts.append("icon") }
                if subtitle != nil { parts.append("subtitle") }
                if detail != nil { parts.append("detail") }
                if chevron { parts.append("chevron") }
                return parts.joined(separator: "-")
            case let .toggle(subtitle, _, isOn):
                // The switch is a reused image, so on/off are different components.
                var parts = ["Row", "toggle"]
                if leading != nil { parts.append("icon") }
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
                    if let leading { leadingView(leading) }
                    labels(subtitle: subtitle, enabled: enabled)
                        .pinCapturedContainer(name: "Labels", layout: PinCaptureLayout(axis: .column, spacing: .spacingXXS, alignment: .leading))
                    Spacer()
                    Toggle("", isOn: isOn)
                        .labelsHidden()
                        .disabled(!enabled)
                        // The switch right-aligns in its frame and draws taller than it, so the crop
                        // cut its right cap and top/bottom. Padding keeps the whole control inside the
                        // captured bounds; the padding is background-coloured, so it's invisible in Figma.
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS)
                        .pinCapturedRasterized(name: "Switch")
                }
            }
        }

        private func leadingView(_ view: AnyView) -> some SwiftUI.View {
            view
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
                if let leading { leadingView(leading) }
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
