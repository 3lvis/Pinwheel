import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class CaptureFidelityTests: XCTestCase {
    private struct Fixture: SwiftUI.View {
        var body: some SwiftUI.View {
            VStack(alignment: .leading, spacing: .spacingL) {
                VStack(alignment: .leading, spacing: .spacingM) {
                    PinLabel("Payment method").font(.subtitleSemibold)
                    HStack(spacing: .spacingS) {
                        PinButton("Card") {}.style(.secondary)
                        PinButton("Cash") {}.style(.secondary)
                    }
                }
                .padding(.spacingL)
                .background(.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: .radiusM))

                VStack(alignment: .trailing, spacing: .spacingS) {
                    PinButton("Skip") {}.style(.tertiary)
                    PinButton("Done") {}
                }
            }
            .padding(.spacingL)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.primaryBackground)
        }
    }

    private func captureRoot() throws -> FigmaNode {
        let document = PinDisplayListCapture.document(Fixture(), name: "Fixture", size: CGSize(width: 402, height: 900), screenHeight: 778)
        return try XCTUnwrap(document, "the fixture should capture into a document").root
    }

    private func firstNode(in node: FigmaNode, where predicate: (FigmaNode) -> Bool) -> FigmaNode? {
        if predicate(node) { return node }
        for child in node.children {
            if let found = firstNode(in: child, where: predicate) { return found }
        }
        return nil
    }

    private func text(of node: FigmaNode) -> String? {
        node.texts?.first?.text ?? node.children.lazy.compactMap { self.text(of: $0) }.first
    }

    func testTallColumnNeedsAContentHeightHostOrItDropsRowsToContainment() throws {
        struct Tall: SwiftUI.View {
            var body: some SwiftUI.View {
                VStack(spacing: .spacingM) {
                    ForEach(0..<12, id: \.self) { PinButton("Button \($0)") {} }
                }
                .padding(.spacingL)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        let tall = try XCTUnwrap(PinDisplayListCapture.document(Tall(), name: "Tall", size: CGSize(width: 402, height: 1600), screenHeight: 778)).root
        XCTAssertEqual(tall.tag, "screen",
                       "a tall column hosted at content height must capture via the reflection path — every row present, counts matched")
        let clamped = try XCTUnwrap(PinDisplayListCapture.document(Tall(), name: "Tall", size: CGSize(width: 402, height: 400), screenHeight: 778)).root
        XCTAssertEqual(clamped.tag, "frame",
                       "a host shorter than the content drops rows into the containment fallback — the regression LiveCaptureHost's content-height sizing avoids")
    }

    // A row that fills the width (the color demo's full-bleed rows) must keep that width, not hug its
    // labels — an AUTO primary size makes the plugin shrink each row to its text.
    func testFullWidthRowKeepsItsWidthNotHuggingItsContent() throws {
        struct FullWidthRows: SwiftUI.View {
            var body: some SwiftUI.View {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { index in
                            HStack {
                                PinLabel("Row \(index)").font(.body).color(.custom(.black))
                                PinLabel("Row \(index)").font(.body).color(.custom(.white))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .spacingL)
                            .padding(.vertical, .spacingM)
                            .background(.tertiaryText)
                        }
                    }
                }
                .background(.primaryBackground)
            }
        }
        let root = try XCTUnwrap(PinDisplayListCapture.document(FullWidthRows(), name: "Rows", size: CGSize(width: 402, height: 900), screenHeight: 778)).root
        let row = try XCTUnwrap(firstNode(in: root) { $0.fillToken == "tertiaryText" && $0.layout != nil }, "a full-width colored row should capture as an auto-layout frame")
        XCTAssertGreaterThan(row.w, 380, "the row spans the width")
        let layout = try XCTUnwrap(row.layout)
        let widthSizing = layout.mode == "row" ? layout.primarySizing : layout.counterSizing
        XCTAssertEqual(widthSizing, "FIXED", "a width-filling row must keep its width fixed so the plugin holds it instead of hugging the labels")
    }

    func testLargeConcentricRadiusResolvesToItsToken() {
        XCTAssertEqual(PinFloatTokens.radiusName(for: 24), "radius-l")
        XCTAssertNil(PinFloatTokens.radiusName(for: 20), "an off-scale radius stays raw, never snapped to a token")
    }

    func testScreenPaddingTokensMatchTheirValuesNeverInheritingStale() throws {
        let layout = try XCTUnwrap(try captureRoot().layout, "the screen must have an auto-layout")
        let tokens = try XCTUnwrap(layout.padTokens, "the screen must carry per-side padding tokens")
        XCTAssertEqual(tokens.count, layout.pad.count)
        for (value, token) in zip(layout.pad, tokens) {
            XCTAssertEqual(token, PinFloatTokens.spacingName(for: value),
                           "each padding side must reference its value-matched token, not an inherited stale one")
        }
        XCTAssertTrue(tokens.contains { $0 != nil }, "a real spacing edge should tokenize")
        XCTAssertTrue(tokens.contains { $0 == nil }, "a positioning-geometry edge should stay raw")
    }

    func testCornerAndSpacingReferenceDesignTokens() throws {
        let root = try captureRoot()
        let card = try XCTUnwrap(firstNode(in: root) { $0.fillToken == "secondaryBackground" },
                                 "the secondaryBackground card should be captured")
        XCTAssertEqual(card.radiusToken, "radius-m",
                       "a radiusM corner must reference the radius token, not just a raw number")
        let gapTokens = allFrameNodes(in: root).compactMap { $0.layout?.gapToken }
        XCTAssertTrue(gapTokens.contains { $0.hasPrefix("spacing-") },
                      "an inferred gap that matches a spacing value must reference the spacing token")
    }

    func testInferredGapBindsTheSpacingTokenDespiteGlyphBearing() {
        // A gap between rendered leaves reads a hair wider than declared — a glyph sits inset within its
        // frame — so a ~9-10 label↔icon gap still binds spacing-s (8).
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 9.33)).gapToken, "spacing-s")
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 10.33)).gapToken, "spacing-s")
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 16)).gapToken, "spacing-l")
        XCTAssertNil(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 20)).gapToken)
    }

    func testMultilineTextCapturesItsCenterAlignment() throws {
        let view = PinLabel("Tap the settings button and choose an option.")
            .multilineTextAlignment(.center)
            .frame(width: 200)
        let root = try XCTUnwrap(PinDisplayListCapture.document(view, name: "Tweakable", size: CGSize(width: 402, height: 900), screenHeight: 778),
                                 "the label should capture into a document").root
        let label = try XCTUnwrap(firstNode(in: root) { text(of: $0)?.hasPrefix("Tap the") == true },
                                  "the wrapping label should be captured")
        XCTAssertEqual(label.textAlign, "center",
                       "a .multilineTextAlignment(.center) label must capture its center alignment")
    }

    func testCardKeepsItsRadiusToken() throws {
        let card = try XCTUnwrap(firstNode(in: captureRoot()) { $0.fillToken == "secondaryBackground" },
                                 "the secondaryBackground card should be captured")
        let radius = try XCTUnwrap(card.radius, "the card should carry a corner radius")
        XCTAssertEqual(radius, Double(CGFloat.radiusM), accuracy: 0.5,
                       "the card corner radius must stay the radiusM token")
    }

    func testFillLessTertiaryKeepsItsMinWidthBox() throws {
        let skip = try XCTUnwrap(firstNode(in: captureRoot()) { $0.name == "Pill" && text(of: $0) == "Skip" },
                                 "the tertiary 'Skip' must capture as a boxed Pill, not bare text")
        XCTAssertEqual(skip.w, Double(PinDisplayListCapture.bareButtonMinWidth), accuracy: 0.5,
                       "a fill-less tertiary button must keep the control min width")
    }

    func testTrailingColumnKeepsItsAlignment() throws {
        let column = try XCTUnwrap(firstNode(in: captureRoot()) {
            $0.layout?.mode == "column" && $0.children.contains { text(of: $0) == "Done" }
        }, "the trailing column should be captured")
        XCTAssertEqual(column.layout?.align, "flex-end",
                       "a .trailing VStack must capture as flex-end cross-axis alignment")
    }

    // Reading `.body` on a UIKit bridge or a SwiftUI-module primitive traps, so the reflector returns nil
    // for them (containment then captures their geometry) rather than crashing the capture.
    func testReflectorSkipsUIKitBridge() {
        struct Bridge: UIViewControllerRepresentable {
            func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
            func updateUIViewController(_ controller: UIViewController, context: Context) {}
        }
        XCTAssertNil(PinViewReflector.reflect(Bridge()))
    }

    func testReflectorSkipsSwiftUIPrimitive() {
        XCTAssertNil(PinViewReflector.reflect(Picker("choice", selection: .constant(0)) { Text("A").tag(0) }))
    }

    func testFlatGroupedScreenKeepsItsRowGrouping() throws {
        struct Fixture: SwiftUI.View {
            var body: some SwiftUI.View {
                VStack(alignment: .leading, spacing: .spacingL) {
                    PinLabel("Apple controls").font(.title)
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel("Toggle").font(.caption).color(.secondary)
                        PinLabel("On").font(.body)
                    }
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel("Slider").font(.caption).color(.secondary)
                        PinLabel("60%").font(.body)
                    }
                }
                .padding(.spacingL)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.primaryBackground)
            }
        }
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Apple controls", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                 "the fixture should capture into a document").root
        XCTAssertNotNil(root.layout,
                        "a flat grouped screen must capture via the semantic column path, not the absolute List fallback")
        XCTAssertTrue(hasGroup(root, "Toggle", "On"),
                      "each row must stay grouped (label + value) — the reflection path preserves it; the collapsed fallback flattens every row into loose siblings")
    }

    func testLeftAlignedLabelColumnCapturesEveryLabel() throws {
        struct Fixture: SwiftUI.View {
            let labels = ["Title", "Subtitle", "Body", "Caption"]
            var body: some SwiftUI.View {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(labels, id: \.self) { label in
                            PinLabel(label)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, .spacingL)
                                .padding(.vertical, .spacingM)
                        }
                    }
                }
                .background(.primaryBackground)
            }
        }
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Typography", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                 "the fixture should capture into a document").root
        let captured = Set(allTextNodes(in: root).compactMap { $0.texts?.first?.text })
        XCTAssertEqual(captured, Set(["Title", "Subtitle", "Body", "Caption"]),
                       "every label must capture as text, not collapse into a single background shape")
    }

    private func hasGroup(_ node: FigmaNode, _ first: String, _ second: String) -> Bool {
        let texts = Set(node.children.compactMap { text(of: $0) })
        if node.tag == "frame", texts == Set([first, second]) { return true }
        return node.children.contains { hasGroup($0, first, second) }
    }

    func testColoredRowsKeepTheirBackgroundFill() throws {
        struct Fixture: SwiftUI.View {
            let rows: [(String, SwiftUI.Color)] = [("Alpha", .red), ("Beta", .green), ("Gamma", .blue)]
            var body: some SwiftUI.View {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(rows, id: \.0) { title, color in
                            HStack {
                                PinLabel(title).color(.custom(.black))
                                PinLabel(title).color(.custom(.white))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .spacingL)
                            .padding(.vertical, .spacingM)
                            .background(color)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.primaryBackground)
            }
        }
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Color", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                 "the fixture should capture into a document").root
        let coloredRows = allFrameNodes(in: root).filter { frame in
            frame.fill != nil && frame.children.contains { $0.texts?.isEmpty == false }
        }
        XCTAssertGreaterThanOrEqual(coloredRows.count, 3,
                                    "each colored row must keep its background fill, not flatten to bare labels on the screen fill")
    }

    func testSymmetricallyInsetRowCentersInALeadingColumn() throws {
        struct Fixture: SwiftUI.View {
            var body: some SwiftUI.View {
                ScrollView {
                    VStack(alignment: .leading, spacing: .spacingL) {
                        PinLabel("Spacing").font(.title)
                        ForEach([CGFloat(8), CGFloat(32)], id: \.self) { pad in
                            PinLabel("bar \(Int(pad))")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, .spacingS)
                                .background(.tertiaryText)
                                .padding(.horizontal, pad)
                        }
                    }
                    .padding(.spacingL)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.primaryBackground)
            }
        }
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Numbers", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                 "the fixture should capture into a document").root
        XCTAssertTrue(hasCenteringSlot(root),
                      "a symmetrically-inset bar must capture wrapped in a centering slot, not pinned to the left")
    }

    private func hasCenteringSlot(_ node: FigmaNode) -> Bool {
        if node.name == "Center", node.children.contains(where: { $0.fill != nil }) { return true }
        return node.children.contains { hasCenteringSlot($0) }
    }

    private func leafCount(_ node: ReflectedNode?) -> Int {
        guard let node else { return 0 }
        switch node {
        case .leaf: return 1
        case .spacer: return 0
        case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
        }
    }

    func testCapturedRootTakesTheGivenScreenName() throws {
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Checkout", size: CGSize(width: 402, height: 900), screenHeight: 778),
                                 "the fixture should capture into a document").root
        XCTAssertEqual(root.name, "Checkout",
                       "the captured screen must take the given name, not its structural root name")
    }


    private func allTextNodes(in node: FigmaNode) -> [FigmaNode] {
        ((node.texts?.isEmpty == false) ? [node] : []) + node.children.flatMap { allTextNodes(in: $0) }
    }

    private func allFrameNodes(in node: FigmaNode) -> [FigmaNode] {
        (node.tag == "frame" ? [node] : []) + node.children.flatMap { allFrameNodes(in: $0) }
    }

    private func imageNodes(in node: FigmaNode) -> [FigmaNode] {
        (node.tag == "image" ? [node] : []) + node.children.flatMap { imageNodes(in: $0) }
    }

    func testPinListRowsCaptureAsTextNodesNotAnEmptyListFrame() throws {
        let list = PinList(state: .loaded, rows: [
            .text("Wi-Fi", detail: "Home", chevron: true) {},
            .toggle("Airplane Mode", isOn: .constant(false)),
        ], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 400), screenHeight: 778),
                                     "the list should capture into a document")
        let titles = allTextNodes(in: document.root).compactMap { $0.texts?.first?.text }
        XCTAssertTrue(titles.contains("Wi-Fi"),
                      "an eager PinList captures its row titles as text nodes; a UIKit-backed List captures an empty frame")
        XCTAssertTrue(titles.contains("Airplane Mode"), "toggle-row labels must capture too")
    }

    func testFullScreenComponentCentersInOneScreen() throws {
        let document = PinDisplayListCapture.document(PinLabel("Nothing here yet"), name: "FullScreen", size: CGSize(width: 402, height: 1600), screenHeight: 778)
        let root = try XCTUnwrap(document, "the full-screen component should capture into a document").root
        XCTAssertEqual(root.h, 778, accuracy: 1, "a centered full-screen component must capture as one screen, not the tall canvas")
    }

    // PinStateView renders several leaves (title + subtitle) but reflects as one, so it falls to containment
    // — the lone-PinLabel case above takes the reflection path, so this is what guards the fallback centering.
    func testCenteredComponentCentersEvenViaTheContainmentFallback() throws {
        let view = PinStateView(.empty(title: "Ready to Move?", subtitle: "Kick things off with your first booking."))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.primaryBackground)
        let root = try XCTUnwrap(PinDisplayListCapture.document(view, name: "StateView", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                 "the state view should capture into a document").root
        XCTAssertEqual(root.h, 778, accuracy: 1,
                       "a centered full-screen component must center in one screen even when it falls to containment")
        XCTAssertLessThan(root.layout?.pad.first ?? 0, 778 * 0.6,
                          "the content must be centered, not top-anchored toward the bottom")
    }
    func testAppearanceDependentSymbolCapturesADistinctDarkVariant() throws {
        let button = PinButton("Continue", systemImage: "arrow.right") {}
        let document = try XCTUnwrap(PinDisplayListCapture.document(button, name: "Button", size: CGSize(width: 402, height: 400), screenHeight: 778),
                                     "the button should capture into a document")
        let symbol = try XCTUnwrap(imageNodes(in: document.root).first { $0.image != nil },
                                   "the button's symbol should be captured with pixels")
        let light = try XCTUnwrap(symbol.image.flatMap { Data(base64Encoded: $0) }.flatMap(UIImage.init(data:)),
                                  "the light symbol image should decode")
        let dark = try XCTUnwrap(symbol.imageDark.flatMap { Data(base64Encoded: $0) }.flatMap(UIImage.init(data:)),
                                 "the symbol must carry a dark variant so it imports correctly in dark mode")
        XCTAssertGreaterThan(averageOpaqueBrightness(light), 200,
                             "the light symbol tints with primaryBackground (near white)")
        XCTAssertLessThan(averageOpaqueBrightness(dark), 60,
                          "the dark symbol tints with primaryBackground (near black), not the light white")
    }

    private func averageOpaqueBrightness(_ image: UIImage) -> Int {
        guard let cg = image.cgImage else { return -1 }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        var sum = 0, count = 0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 10 {
            sum += (Int(pixels[index]) + Int(pixels[index + 1]) + Int(pixels[index + 2])) / 3
            count += 1
        }
        return count > 0 ? sum / count : -1
    }

}
