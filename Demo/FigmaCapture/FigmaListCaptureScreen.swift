import SwiftUI
import Pinwheel

// Captures a list's rows structurally (editable text, not a flat image). The rows are the same
// `PinList.Row` values the app uses; a lazy `List` only lays out visible rows, but the data source
// is finite, so laying them out eagerly (a `VStack`) makes every row — below the fold included —
// resolve its frame and capture its `PinLabel`s. Structured beats the rasterized scroll-stitch;
// this is the from-first-principles path. (Macros come later — this is hand-wired.)
struct FigmaListCaptureScreen: SwiftUI.View {
    private let rows: [PinList.Row] = (1...30).map { .text("Row \($0)", detail: "$\($0 * 3).00") }

    var body: some SwiftUI.View {
        FigmaCaptureHost(name: "List", content: content) { document in
            FigmaCaptureFile.write(document)
        }
    }

    private var content: some SwiftUI.View {
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
