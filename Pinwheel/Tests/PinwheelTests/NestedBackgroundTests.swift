import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class NestedBackgroundTests: XCTestCase {
    private func columnLayout(pad: CGFloat) -> FigmaLayout {
        FigmaLayout(PinCaptureLayout(axis: .column, spacing: 8, padding: EdgeInsets(top: pad, leading: pad, bottom: pad, trailing: pad)))
    }

    // A card HStack (secondaryBackground, padded) wraps a no-text thumbnail and a content VStack. Reflection
    // matches the card's background to BOTH containers — they share the same text set, because the thumbnail
    // carries no text to tell them apart — so the inner VStack duplicates the fill and the 12pt padding,
    // inflating every row. The inner copy must be stripped so the card is filled and padded exactly once.
    func testNestedContainerDropsItsParentsDuplicatedBackground() {
        let fill = RGBA(r: 0.95, g: 0.97, b: 0.98, a: 1)
        let text = FigmaNode(tag: "text", x: 0, y: 0, w: 100, h: 20, children: [])
        let content = FigmaNode(tag: "frame", x: 0, y: 0, w: 200, h: 80,
                                fill: fill, fillToken: "secondaryBackground", radius: 12, radiusToken: "radius-m",
                                layout: columnLayout(pad: 12), children: [text])
        let thumbnail = FigmaNode(tag: "frame", x: 0, y: 0, w: 64, h: 64, children: [])
        let card = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 88,
                             fill: fill, fillToken: "secondaryBackground", radius: 12, radiusToken: "radius-m",
                             layout: columnLayout(pad: 12), children: [thumbnail, content])

        let result = PinDisplayListCapture.stripDuplicateNestedBackground(card)

        XCTAssertEqual(result.fillToken, "secondaryBackground", "the card keeps its background")
        let inner = result.children[1]
        XCTAssertNil(inner.fillToken, "the nested duplicate fill is stripped")
        XCTAssertNil(inner.radiusToken, "the nested duplicate radius is stripped")
        XCTAssertEqual(inner.layout?.pad, [0, 0, 0, 0], "the duplicated padding is zeroed")
    }

    // A list of rows each carrying the screen's own fill (PinList rows are primaryBackground on a
    // primaryBackground screen, so their frame spans the row insets) are NOT a duplicated wrapper — a
    // duplicate is a single child that wraps the parent, not many stacked siblings. They must be kept.
    func testManySameFillSiblingRowsAreKept() {
        func row() -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 36, fill: RGBA(r: 1, g: 1, b: 1, a: 1), fillToken: "primaryBackground",
                      layout: columnLayout(pad: 8), children: [FigmaNode(tag: "text", x: 0, y: 0, w: 100, h: 20, children: [])])
        }
        let screen = FigmaNode(tag: "screen", x: 0, y: 0, w: 300, h: 300,
                               fill: RGBA(r: 1, g: 1, b: 1, a: 1), fillToken: "primaryBackground",
                               layout: columnLayout(pad: 0), children: [row(), row(), row()])
        let result = PinDisplayListCapture.stripDuplicateNestedBackground(screen)
        for (index, row) in result.children.enumerated() {
            XCTAssertEqual(row.fillToken, "primaryBackground", "row \(index) keeps its fill")
            XCTAssertEqual(row.layout?.pad, [8, 8, 8, 8], "row \(index) keeps its insets")
        }
    }

    // A genuinely different nested fill (a card on a differently-coloured screen) is not a duplicate and stays.
    func testNestedContainerWithADifferentFillIsUntouched() {
        let card = FigmaNode(tag: "frame", x: 0, y: 0, w: 200, h: 80,
                             fill: RGBA(r: 0.9, g: 0.9, b: 0.9, a: 1), fillToken: "secondaryBackground",
                             layout: columnLayout(pad: 12), children: [])
        let screen = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 300,
                               fill: RGBA(r: 1, g: 1, b: 1, a: 1), fillToken: "primaryBackground",
                               layout: columnLayout(pad: 0), children: [card])
        let result = PinDisplayListCapture.stripDuplicateNestedBackground(screen)
        XCTAssertEqual(result.children[0].fillToken, "secondaryBackground", "a distinct nested fill is kept")
    }
}
