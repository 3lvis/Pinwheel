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

    // VStack, not List: a List's UIKit-backed cells don't render off-screen, so Figma capture reads them empty.
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
