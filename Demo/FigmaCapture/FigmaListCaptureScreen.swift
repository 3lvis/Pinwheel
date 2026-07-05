import SwiftUI
import Pinwheel

// Rows laid out eagerly (a VStack, not the lazy List) so every row — below the fold too — captures;
// the capture wiring lives in PinList.Row, not here.
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
