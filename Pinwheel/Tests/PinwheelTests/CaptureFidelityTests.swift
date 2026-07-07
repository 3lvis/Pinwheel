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
        // A gap measured between rendered leaves reads a hair wider than the declared spacing (a glyph or
        // symbol sits inset within its frame), so a label↔icon gap of ~9-10 must still bind spacingS (8).
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 9.33)).gapToken, "spacing-s")
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 10.33)).gapToken, "spacing-s")
        // An exact token still binds; a gap that isn't near any token stays raw.
        XCTAssertEqual(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 16)).gapToken, "spacing-l")
        XCTAssertNil(FigmaLayout(PinCaptureLayout(axis: .row, spacing: 20)).gapToken)
    }

    // A multi-line label's paragraph alignment must be captured — a `.multilineTextAlignment(.center)`
    // message (the Tweakable empty state) read as left-aligned in Figma because the alignment was dropped.
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

    // A scrolling column of left-aligned labels (the Typography demo) must capture every label. The
    // labels are narrower than the full width, so the column's wrapping group looked like a padded
    // fill-less button — emitting a phantom transparent box that orphaned the labels in containment and
    // collapsed the whole screen to one background shape. A button wraps a single label; a multi-text
    // group is a layout container, not a button.
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

    // A frame whose children are exactly the two texts — a tight grouped row the reflection path
    // preserves. The collapsed containment fallback emits every row's texts as loose siblings of the
    // root, so only the root (holding every text) would contain both — never a two-child group.
    private func hasGroup(_ node: FigmaNode, _ first: String, _ second: String) -> Bool {
        let texts = Set(node.children.compactMap { text(of: $0) })
        if node.tag == "frame", texts == Set([first, second]) { return true }
        return node.children.contains { hasGroup($0, first, second) }
    }

    // Rows with their own colored background (the Color token showcase) must keep that fill. The rows'
    // side-by-side dual labels made the fallback read the screen as a horizontal list and flatten each
    // row to its labels, dropping the background — so the colored rows captured as bare text on white.
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

    // A row inset symmetrically (a spacing bar that shrinks toward the middle) is centered. In a column
    // shared with a leading section header, the single cross-alignment is leading, which would pin the
    // bar to the left. It must instead capture wrapped in a full-width centering slot.
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

    // PinStateView reflects as a single leaf but renders several (title + subtitle), so it can't take the
    // reflection path and falls to containment. Its centered empty state must still capture centered in
    // one screen, not top-anchored to the bottom. (The lone-PinLabel case above takes the reflection
    // path, so it never guarded the fallback centering — this does.)
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

    // A primary button's symbol tints with the appearance-dependent primaryBackground token — white in
    // light, black in dark. The single light-rendered PNG imported into Figma's dark mode as a white
    // arrow on cyan where it should be black, so the node must carry a distinct dark variant.
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

    // A List separator is a SwiftUI Divider — Apple's separator color, which matches no Pinwheel token.
    // A raw (untokenized) fill only carries its light value, so it imported with the light separator
    // color on the dark background; it must carry a dark fill to adapt like a tokenized color does.
    func testNonTokenizedSeparatorCapturesADarkFill() throws {
        let list = PinList(state: .loaded, rows: [.text("A") {}, .text("B") {}], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 400), screenHeight: 778),
                                     "the list should capture into a document")
        let separator = try XCTUnwrap(firstNode(in: document.root) { $0.h > 0 && $0.h < 2 && $0.fill != nil },
                                      "the list should capture a hairline separator with a fill")
        let light = try XCTUnwrap(separator.fill)
        let dark = try XCTUnwrap(separator.fillDark,
                                 "a non-tokenized fill must carry a dark variant so it adapts on import into dark mode")
        XCTAssertTrue(abs(dark.r - light.r) > 0.03 || abs(dark.a - light.a) > 0.03,
                      "the dark separator must differ from the light one, not repeat the light value")
    }

    // Merging a dark capture into a light one carries every node's dark pixels and dark fill onto its
    // light twin, so a control captured on the live screen in each appearance adapts on import.
    func testMergingDarkVariantsCarriesDarkImageAndFill() {
        func document(image: String, fill: RGBA) -> FigmaDocument {
            let leaf = FigmaNode(tag: "image", x: 0, y: 0, w: 51, h: 31, fill: fill, image: image, children: [])
            return FigmaDocument(width: 100, height: 100,
                                 root: FigmaNode(tag: "frame", x: 0, y: 0, w: 100, h: 100, children: [leaf]),
                                 tokens: [], textStyles: [])
        }
        let merged = PinDisplayListCapture.mergingDarkVariants(
            light: document(image: "light", fill: RGBA(r: 1, g: 1, b: 1, a: 1)),
            dark: document(image: "dark", fill: RGBA(r: 0, g: 0, b: 0, a: 1))
        )
        XCTAssertEqual(merged.root.children[0].imageDark, "dark", "the dark capture's pixels become imageDark")
        XCTAssertEqual(merged.root.children[0].fillDark?.r, 0, "the dark capture's fill becomes fillDark")
        XCTAssertEqual(merged.root.children[0].image, "light", "the light capture stays the base image")
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
