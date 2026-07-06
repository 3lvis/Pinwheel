import SwiftUI
import Pinwheel

struct PinTypographyDemo: SwiftUI.View {
    private let styles: [(String, PinTextStyle)] = [
        ("Title", .title),
        ("Subtitle", .subtitle),
        ("Subtitle Semibold", .subtitleSemibold),
        ("Body", .body),
        ("Footnote", .footnote),
        ("Caption", .caption)
    ]

    var body: some SwiftUI.View {
        List(styles, id: \.0) { title, style in
            PinLabel(title).font(style)
                .listRowBackground(Color.primaryBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.primaryBackground)
    }
}
