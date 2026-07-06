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

    // A settings list (PinList) must capture as a vertical column of rows. It regressed to a single
    // horizontal row: PinList falls back to containment, its ungrouped leaves overlap in Y (icon beside
    // title), so axis inference read the whole list as one row — and the Figma auto-layout import then
    // laid every row left-to-right, off-screen (only the first row showed).
    func testListCapturesAsAVerticalColumn() throws {
        let list = PinList(state: .loaded, rows: [
            .text("Account", icon: Image(systemName: "person.crop.circle.fill"), subtitle: "Signed in", chevron: true) {},
            .text("Wi-Fi", icon: Image(systemName: "wifi"), detail: "Home", chevron: true) {},
            .toggle("Airplane Mode", icon: Image(systemName: "airplane"), isOn: .constant(false)),
        ], onRetry: {})
        let document = try XCTUnwrap(PinDisplayListCapture.document(list, name: "List", size: CGSize(width: 402, height: 1600), screenHeight: 778),
                                     "the list should capture into a document")
        XCTAssertEqual(document.root.layout?.mode, "column",
                       "a settings list must capture as a vertical column of rows, not one horizontal row")
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
}
