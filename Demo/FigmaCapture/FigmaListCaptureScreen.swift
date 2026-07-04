import SwiftUI
import Pinwheel

// Proves the *real* component self-captures: these are actual `PinList.Row` values, and the capture
// wiring lives in `PinList.Row` itself (`.pinCapturedContainer`), not this screen. Laying the finite
// rows out eagerly (a `VStack`, not the lazy `List`) makes every row — below the fold included —
// resolve and capture its grouped, editable labels. (The rows' native bits — chevron/`Toggle` — are
// still rasterization, a host concern; structured labels + grouping come from the library.)
struct FigmaListCaptureScreen: SwiftUI.View {
    private let rows: [PinList.Row] = (1...10).map { index in
        index.isMultiple(of: 3)
            ? .toggle("Row \(index)", subtitle: "Supporting text", isOn: .constant(index.isMultiple(of: 2)))
            : .text("Row \(index)", subtitle: "Supporting text", detail: "$\(index * 3)", chevron: true)
    }

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
