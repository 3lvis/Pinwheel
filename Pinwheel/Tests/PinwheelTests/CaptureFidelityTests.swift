import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

// Pins the *shape* of the captured IR, not just "it didn't crash": a silent drift in the card's
// radius token, the fill-less button's min-width box, or cross-axis alignment fails here rather than
// shipping to Figma. The fixture exercises the same constructs the button demo folds in — a filled/
// clipped card and a trailing column — so this and the catalog-open UI test cover it from both sides.
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
        XCTAssertEqual(skip.w, Double(PinButton.minTitledWidth), accuracy: 0.5,
                       "a fill-less tertiary button must keep the control min width")
    }

    func testTrailingColumnKeepsItsAlignment() throws {
        let column = try XCTUnwrap(firstNode(in: captureRoot()) {
            $0.layout?.mode == "column" && $0.children.contains { text(of: $0) == "Done" }
        }, "the trailing column should be captured")
        XCTAssertEqual(column.layout?.align, "flex-end",
                       "a .trailing VStack must capture as flex-end cross-axis alignment")
    }

    // The reflector must skip views whose `.body` traps — a UIKit bridge and any SwiftUI-module
    // primitive — returning nil (containment then captures their geometry) rather than calling `.body`.
    // Trapping there crashed the app while capturing UIKit / Apple-controls demos.
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

    // A rasterized Apple control (Toggle/Slider/DatePicker via `pinCapturedRasterized`) wraps a SwiftUI
    // primitive the reflector otherwise skips. It must still count as one leaf, or the reflected count
    // won't match the rendered components and the whole screen falls back to containment — which misread
    // the Apple-controls VStack as an absolute "List" (mangled layout, wrong frame name).
    func testReflectorCountsARasterizedControlAsALeaf() {
        struct Fixture: SwiftUI.View {
            var body: some SwiftUI.View {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    PinLabel("Toggle").font(.caption).color(.secondary)
                    Toggle("", isOn: .constant(true)).labelsHidden().pinCapturedRasterized(name: "Toggle")
                }
            }
        }
        XCTAssertEqual(leafCount(PinViewReflector.reflect(Fixture())), 2,
                       "the rasterized control must count as a leaf, alongside its label")
    }

    // A flat screen — a column of grouped rows where every leaf is a direct child of the root and none
    // nests another (the Apple-controls layout: each control rasterizes to one leaf, a platform view) —
    // must capture via the semantic reflection path, keeping each row grouped. `orderedComponents` used to
    // collapse such a root to a single component, desyncing the reflected count into the containment
    // fallback, which flattens the rows (and, when they overlap in Y, misreads the screen as a "List").
    // Bare text rows stand in for the controls so the leaves are deterministic and never nest off-screen.
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

    // A frame whose children are exactly the two texts — a tight grouped row the reflection path
    // preserves. The collapsed containment fallback emits every row's texts as loose siblings of the
    // root, so only the root (holding every text) would contain both — never a two-child group.
    private func hasGroup(_ node: FigmaNode, _ first: String, _ second: String) -> Bool {
        let texts = Set(node.children.compactMap { text(of: $0) })
        if node.tag == "frame", texts == Set([first, second]) { return true }
        return node.children.contains { hasGroup($0, first, second) }
    }

    private func leafCount(_ node: ReflectedNode?) -> Int {
        guard let node else { return 0 }
        switch node {
        case .leaf: return 1
        case .spacer: return 0
        case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
        }
    }

    // The captured screen takes the given name so the Figma frame reads the component title, not its
    // structural root name (the Apple-controls capture showed "List" — its misinferred root — as the
    // frame name, since `name` was accepted but dropped).
    func testCapturedRootTakesTheGivenScreenName() throws {
        let root = try XCTUnwrap(PinDisplayListCapture.document(Fixture(), name: "Checkout", size: CGSize(width: 402, height: 900), screenHeight: 778),
                                 "the fixture should capture into a document").root
        XCTAssertEqual(root.name, "Checkout",
                       "the captured screen must take the given name, not its structural root name")
    }

    // A settings list (PinList) is UITableView-backed; its rows fall back to containment and overlap in
    // Y (icon beside title). It must capture with absolute positions — each row where it rendered — not
    // as a reflowable auto-layout frame (the plugin reflowed it and misplaced icons/toggles onto the
    // wrong rows) and not as one horizontal row (which collapsed every row off-screen).
    func testListCapturesRowsAtTheirVerticalPositions() throws {
        let list = PinList(state: .loaded, rows: [
            .text("Account", icon: Image(systemName: "person.crop.circle.fill"), subtitle: "Signed in", chevron: true) {},
            .text("Wi-Fi", icon: Image(systemName: "wifi"), detail: "Home", chevron: true) {},
            .toggle("Airplane Mode", icon: Image(systemName: "airplane"), isOn: .constant(false)),
        ], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                     "the list should capture into a document")
        XCTAssertNil(document.root.layout,
                     "a list must capture with absolute positions, not a reflowable auto-layout frame")
        XCTAssertTrue(allFrameNodes(in: document.root).allSatisfy { $0.layout == nil },
                      "every list row must be absolute too, so the plugin doesn't reflow a two-line row's title/subtitle side by side")
        let titleYs = allTextNodes(in: document.root).compactMap { node -> Double? in
            (node.texts?.first?.text).flatMap { ["Account", "Wi-Fi", "Airplane Mode"].contains($0) ? node.y : nil }
        }.sorted()
        XCTAssertGreaterThan((titleYs.last ?? 0) - (titleYs.first ?? 0), 60,
                             "list rows must stack vertically, not collapse onto one row")
    }

    private func allTextNodes(in node: FigmaNode) -> [FigmaNode] {
        ((node.texts?.isEmpty == false) ? [node] : []) + node.children.flatMap { allTextNodes(in: $0) }
    }

    private func allFrameNodes(in node: FigmaNode) -> [FigmaNode] {
        (node.tag == "frame" ? [node] : []) + node.children.flatMap { allFrameNodes(in: $0) }
    }

    // A list row's icon/chevron must capture its pixels. SwiftUI's renderer returns a blank placeholder
    // for UIKit-hosted content (a List is UITableView-backed), so these came through as empty image
    // nodes — recovered by rendering the host layer and cropping.
    func testListRowIconsCaptureTheirPixels() throws {
        let list = PinList(state: .loaded, rows: [
            .text("Wi-Fi", icon: Image(systemName: "wifi"), detail: "Home", chevron: true) {},
        ], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                     "the list should capture into a document")
        let images = imageNodes(in: document.root)
        XCTAssertFalse(images.isEmpty, "a list row with an icon and chevron should capture image leaves")
        XCTAssertTrue(images.allSatisfy { $0.image != nil },
                      "every captured icon/chevron must carry pixel data, not a blank placeholder")
    }

    private func imageNodes(in node: FigmaNode) -> [FigmaNode] {
        (node.tag == "image" ? [node] : []) + node.children.flatMap { imageNodes(in: $0) }
    }

    // A full-screen component (fills the height, content centered — an empty state) must capture as one
    // screen with the content centered, not float in the oversized render canvas. Regressed to the full
    // 1600pt canvas when a hugging/centered component was captured naively.
    func testFullScreenComponentCentersInOneScreen() throws {
        let document = PinDisplayListCapture.document(PinLabel("Nothing here yet"), name: "FullScreen", size: CGSize(width: 402, height: 1600), screenHeight: 778)
        let root = try XCTUnwrap(document, "the full-screen component should capture into a document").root
        XCTAssertEqual(root.h, 778, accuracy: 1, "a centered full-screen component must capture as one screen, not the tall canvas")
    }
    // The icon crop must contain the rendered symbol, not the blank safe-area strip above it. The host
    // layer renders with the safe-area inset the DisplayList frames omit, so cropping at the bare frame
    // grabbed the empty region above the content (icons came out blank / shifted a row in Figma).
    func testListIconCropReadsThroughTheSafeAreaInset() throws {
        let list = PinList(state: .loaded, rows: [
            .text("Wi-Fi", icon: Image(systemName: "wifi"), chevron: true) {},
        ], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                     "the list should capture into a document")
        let icon = try XCTUnwrap(imageNodes(in: document.root).first { $0.x < 40 && $0.image != nil },
                                 "the row's icon should be captured with pixels")
        let data = try XCTUnwrap(Data(base64Encoded: icon.image!))
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertTrue(hasVisiblePixels(image),
                      "the icon crop must contain the rendered symbol, not the blank safe-area region")
    }

    private func hasVisiblePixels(_ image: UIImage) -> Bool {
        guard let cg = image.cgImage else { return false }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let (r, g, b, a) = (pixels[index], pixels[index + 1], pixels[index + 2], pixels[index + 3])
            if a > 20, r < 230 || g < 230 || b < 230 { return true }
        }
        return false
    }
}
