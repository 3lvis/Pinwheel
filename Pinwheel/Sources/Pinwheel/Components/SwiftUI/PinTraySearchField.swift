import SwiftUI

/// The field a search tray floats over its results. Takes focus as it appears.
public struct PinTraySearchField: SwiftUI.View {
    private let prompt: String
    @SwiftUI.Binding private var text: String

    @Environment(\.pinwheelTheme) private var theme
    @FocusState private var focused: Bool

    public init(_ prompt: String, text: SwiftUI.Binding<String>) {
        self.prompt = prompt
        _text = text
    }

    public var body: some SwiftUI.View {
        HStack(spacing: .spacing2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondaryText)
            TextField(prompt, text: $text)
                .font(PinTextStyle.body.font(in: theme))
                .foregroundStyle(.primaryText)
                .focused($focused)
                .accessibilityIdentifier("pinwheel.tray.search")
        }
        .padding(.horizontal, .spacing4)
        .frame(minHeight: .minimumControlHeight)
        .background(
            RoundedRectangle(cornerRadius: .radiusL)
                .fill(Color.secondaryBackground)
        )
        .onAppear { focused = true }
    }
}
