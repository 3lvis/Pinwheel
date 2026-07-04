import SwiftUI
import UIKit
import Pinwheel

// Proves lazy-list capture: a finite SwiftUI `List` (lazy — rows below the fold don't exist until
// scrolled into view) captured in full by scroll-and-stitch, emitted as one tall image node. The
// data source is fixed, so paging the scroll view reaches every row.
struct FigmaTableCaptureScreen: SwiftUI.View {
    var body: some SwiftUI.View {
        List(0..<30, id: \.self) { index in
            HStack {
                PinLabel("Row \(index + 1)").font(.body)
                Spacer()
                PinLabel("$\((index + 1) * 3).00").font(.caption).color(.secondary)
            }
            .listRowBackground(Color.primaryBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.primaryBackground)
        .task {
            // Let the list lay out its first page before driving the scroll.
            try? await Task.sleep(nanoseconds: 600_000_000)
            await captureAndPush()
        }
    }

    @MainActor
    private func captureAndPush() async {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let scrollView = ScrollStitch.scrollView(in: window),
              let result = await ScrollStitch.capture(scrollView, in: window),
              let base64 = result.image.pngData()?.base64EncodedString() else { return }

        let image = FigmaNode(
            tag: "image", x: 0, y: 0, w: result.size.width, h: result.size.height,
            component: "TableRows", image: base64, children: []
        )
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: result.size.width, h: result.size.height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            name: "Table", children: [image]
        )
        FigmaCaptureFile.write(FigmaDocument(
            width: result.size.width, height: result.size.height, root: root,
            tokens: [], textStyles: []
        ))
    }
}
