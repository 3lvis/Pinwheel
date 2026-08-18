import SwiftUI

/// A sentence ending in an underlined phrase that opens a web page.
public struct PinTrayLink: SwiftUI.View {
    private let text: String
    private let phrase: String
    private let open: () -> Void
    private var style: PinTextStyle = .body

    @Environment(\.pinwheelTheme) private var theme

    public init(_ text: String, phrase: String, open: @escaping () -> Void) {
        self.text = text
        self.phrase = phrase
        self.open = open
    }

    public func font(_ font: PinTextStyle) -> PinTrayLink {
        var copy = self
        copy.style = font
        return copy
    }

    public var body: some SwiftUI.View {
        SwiftUI.Button(action: open) {
            let oneParagraph = Text(text) + Text(" ") + Text(phrase).underline()
            oneParagraph
                .font(style.font(in: theme))
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pinwheel.tray.link.\(phrase)")
    }
}
