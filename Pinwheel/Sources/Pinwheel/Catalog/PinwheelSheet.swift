import SwiftUI

struct PinwheelSheetModel {
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

    struct Commit {
        let title: String
        let action: () -> Void

        init(_ title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
    }

    let title: String
    var leading: Leading = .close
    var commit: Commit?
}

// Not a `List`: a scroll view takes all the height it is offered, so measuring one reports the
// sheet's height back to itself and the fitted detent silently does nothing.
struct PinwheelSheet<Content: SwiftUI.View, Trailing: SwiftUI.View>: SwiftUI.View {
    let model: PinwheelSheetModel
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
                    .overlay(Color.tertiaryText)
                    .padding(.horizontal, .spacing6)
                content()
                if let commit = model.commit {
                    PinButton(commit.title, action: commit.action)
                        .style(.primary)
                        .fullWidth()
                        .padding(.horizontal, .spacing6)
                        .padding(.top, .spacing6)
                }
            }
            .padding(.bottom, .spacing6)
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
            PinLabel(model.title)
                .font(.subtitleSemibold)
                .accessibilityIdentifier("pinwheel.sheet.\(model.title).theme.\(theme.name)")
            HStack {
                SwiftUI.Button {
                    dismiss()
                } label: {
                    Image(systemName: model.leading.symbol)
                        .font(PinTextStyle.body.font(in: theme))
                        .symbolRenderingMode(.monochrome)
                        .imageScale(.large)
                }
                .tint(.primaryText)
                .accessibilityLabel(model.leading.label)
                Spacer()
                trailing()
                    .tint(.primaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: .minimumControlHeight)
        .padding(.horizontal, .spacing6)
        .padding(.vertical, .spacing2)
    }
}

extension PinwheelSheet where Trailing == EmptyView {
    init(_ model: PinwheelSheetModel, @ViewBuilder content: @escaping () -> Content) {
        self.init(model: model, content: content, trailing: { EmptyView() })
    }
}

/// The border, not the fill, carries the selection: colour alone would need 3:1 against its
/// surroundings to stand on its own (WCAG 1.4.1, 1.4.11), which a soft fill does not reach.
struct PickerRow: SwiftUI.View {
    let title: String
    let isSelected: Bool
    let select: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: select) {
            HStack {
                PinLabel(title).color(isSelected ? .action : .primary)
                Spacer()
            }
            .padding(.horizontal, .spacing3)
            .padding(.vertical, .spacing3)
            .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .radiusM)
                    .fill(isSelected ? Color.actionText.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                    .strokeBorder(isSelected ? Color.actionText : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .padding(.horizontal, .spacing3)
        }
        .buttonStyle(.plain)
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
