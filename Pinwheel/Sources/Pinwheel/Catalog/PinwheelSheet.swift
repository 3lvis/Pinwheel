import SwiftUI

// Not a `List`: a scroll view takes all the height it is offered, so measuring one reports the
// sheet's height back to itself and the fitted detent silently does nothing.
struct PinwheelSheet<Content: SwiftUI.View, Trailing: SwiftUI.View>: SwiftUI.View {
    enum Leading {
        case close
        case back

        var symbol: String {
            switch self {
            case .close: return "xmark"
            case .back: return "chevron.backward"
            }
        }

        var label: String {
            switch self {
            case .close: return "Close"
            case .back: return "Back"
            }
        }
    }

    let title: String
    var leading: Leading = .close
    var showsDone: Bool = false
    @ViewBuilder let content: () -> Content
    @ViewBuilder var trailing: () -> Trailing

    @SwiftUI.State private var contentHeight: CGFloat = 0
    @SwiftUI.State private var safeAreaBottom: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pinwheelTheme) private var theme

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider()
                    .frame(height: 1)
                    .overlay(Color.secondaryBackground)
                    .padding(.horizontal, .spacingXL)
                content()
                if showsDone {
                    PinButton("Done") { dismiss() }
                        .style(.primary)
                        .fullWidth()
                        .padding(.horizontal, .spacingXL)
                        .padding(.top, .spacingXL)
                }
            }
            .padding(.bottom, .spacingXL)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(.primaryBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { safeAreaBottom = $0 }
        .presentationDragIndicator(.hidden)
        // A sheet adds its bottom safe-area inset on top of the detent, so asking for the content's
        // height yields a sheet that much taller and an empty strip under the content.
        .presentationDetents([.height(max(contentHeight - safeAreaBottom, 0)), .large])
    }

    private var header: some SwiftUI.View {
        ZStack {
            PinLabel(title)
                .font(.subtitleSemibold)
                .accessibilityIdentifier("pinwheel.sheet.\(title).theme.\(theme.name)")
            HStack {
                SwiftUI.Button {
                    dismiss()
                } label: {
                    Image(systemName: leading.symbol)
                        .font(PinTextStyle.subtitleSemibold.font(in: theme))
                }
                .tint(.primaryText)
                .accessibilityLabel(leading.label)
                Spacer()
                trailing()
                    .tint(.primaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: .minimumControlHeight)
        .padding(.horizontal, .spacingXL)
        .padding(.vertical, .spacingS)
    }
}

extension PinwheelSheet where Trailing == EmptyView {
    init(
        title: String,
        leading: Leading = .close,
        showsDone: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title: title, leading: leading, showsDone: showsDone, content: content, trailing: { EmptyView() })
    }
}

struct PickerRow: SwiftUI.View {
    let title: String
    let isSelected: Bool
    let select: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: select) {
            HStack {
                PinLabel(title).color(isSelected ? .action : .primary)
                Spacer()
                PickerRadio(isSelected: isSelected)
            }
            .padding(.horizontal, .spacingXL)
            .padding(.vertical, .spacingM)
            .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PickerRadio: SwiftUI.View {
    let isSelected: Bool

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = .spacingXL

    var body: some SwiftUI.View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Color.actionText : Color.tertiaryText, lineWidth: 2)
            if isSelected {
                Circle()
                    .fill(Color.actionText)
                    .padding(5)
            }
        }
        .frame(width: size, height: size)
    }
}

struct ThemeSampleRow: SwiftUI.View {
    let theme: PinwheelTheme
    let isSelected: Bool
    let select: () -> Void

    var body: some SwiftUI.View {
        PickerRow(title: theme.name, isSelected: isSelected, select: select)
            .environment(\.pinwheelTheme, theme)
            .accessibilityIdentifier("pinwheel.theme.\(theme.id)")
    }
}
