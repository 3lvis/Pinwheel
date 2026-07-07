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

    // Rows live in a VStack, not a List: a List's UIKit-backed cells don't render off-screen, so the
    // Figma capture reads them as an empty background; a VStack renders into SwiftUI's own tree.
    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(styles, id: \.0) { title, style in
                    PinLabel(title).font(style)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, .spacingL)
                        .padding(.vertical, .spacingM)
                }
            }
        }
        .background(.primaryBackground)
    }
}
