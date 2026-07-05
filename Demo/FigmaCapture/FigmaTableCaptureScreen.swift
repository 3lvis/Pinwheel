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
            // Poll until the List has built its scroll view with content — the signal we actually
            // need — instead of guessing a fixed delay. Each yield lets the runloop lay the List out.
            var attempts = 0
            while readyScrollView() == nil && attempts < 600 {
                attempts += 1
                await Task.yield()
            }
            await captureAndPush()
        }
    }

    @MainActor
    private func readyScrollView() -> UIScrollView? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let scroll = ScrollStitch.scrollView(in: window), scroll.contentSize.height > 0 else { return nil }
        return scroll
    }

    @MainActor
    private func captureAndPush() async {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let scrollView = ScrollStitch.scrollView(in: window),
              let result = await ScrollStitch.capture(scrollView, in: window) else { return }

        let children = result.pages.compactMap { page -> FigmaNode? in
            guard let base64 = page.image.pngData()?.base64EncodedString() else { return nil }
            return FigmaNode(
                tag: "image", x: 0, y: page.offset, w: result.size.width, h: page.height,
                component: "TableRows", image: base64, children: []
            )
        }
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: result.size.width, h: result.size.height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            name: "Table", children: children
        )
        FigmaCaptureFile.write(FigmaDocument(
            width: result.size.width, height: result.size.height, root: root,
            tokens: [], textStyles: []
        ))
    }
}
