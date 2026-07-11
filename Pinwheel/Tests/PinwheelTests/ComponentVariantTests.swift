import XCTest
@testable import Pinwheel

@MainActor
final class ComponentVariantTests: XCTestCase {
    private func text() -> FigmaNode {
        FigmaNode(tag: "text", x: 0, y: 0, w: 40, h: 20, children: [])
    }
    private func pill() -> FigmaNode {
        FigmaNode(tag: "frame", x: 0, y: 0, w: 40, h: 20, children: [text()])
    }
    // A cart row: title + optional SALE pill, then a price + optional strikethrough was-price.
    private func row(sale: Bool) -> FigmaNode {
        let title = FigmaNode(tag: "frame", x: 0, y: 0, w: 200, h: 20, children: sale ? [text(), pill()] : [text()])
        let price = FigmaNode(tag: "frame", x: 0, y: 20, w: 200, h: 20, children: sale ? [text(), text()] : [text()])
        return FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 60, children: [title, price])
    }

    // A gallery of rows that share a structure but each carry a different photo should group as one
    // component with the image as a per-instance override — not stay three plain frames, since a Figma
    // instance can swap an image fill.
    func testSameStructureRowsWithDifferentImagesGroup() {
        func imageRow(_ bytes: String) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 80,
                      children: [FigmaNode(tag: "image", x: 0, y: 0, w: 64, h: 64, image: bytes, children: []), text()])
        }
        let parent = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 240,
                               children: [imageRow("AAAA"), imageRow("BBBB"), imageRow("CCCC")])
        let result = PinDisplayListCapture.componentizeRepeatedChildren(parent)
        let keys = result.children.map { $0.component }
        XCTAssertTrue(keys.allSatisfy { $0 != nil }, "every row is part of the component")
        XCTAssertEqual(Set(keys.compactMap { $0 }).count, 1, "same-structure rows group as ONE component even though each has a different image")
    }

    // Three identical sale rows and one no-sale row: the no-sale row differs only by the optional SALE pill
    // and was-price, so it must join the same component as an instance, with those two layers inserted as
    // hidden placeholders — not stay a separate frame.
    func testNoSaleRowJoinsTheSaleComponentWithHiddenOptionalLayers() {
        let parent = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 240,
                               children: [row(sale: true), row(sale: true), row(sale: false), row(sale: true)])
        let result = PinDisplayListCapture.componentizeRepeatedChildren(parent)

        let keys = result.children.map { $0.component }
        XCTAssertTrue(keys.allSatisfy { $0 != nil }, "every row is part of the component")
        XCTAssertEqual(Set(keys.compactMap { $0 }).count, 1, "all four rows share ONE component — the no-sale row is a variant, not its own frame")

        // The no-sale row (index 2) is normalized to the master's structure: its title row now carries a
        // hidden SALE pill and its price row a hidden was-price.
        let noSale = result.children[2]
        let titleRow = noSale.children[0]
        let priceRow = noSale.children[1]
        XCTAssertEqual(titleRow.children.count, 2, "the title row gains the SALE pill placeholder")
        XCTAssertEqual(titleRow.children.last?.hidden, true, "the inserted SALE pill is hidden")
        XCTAssertEqual(priceRow.children.count, 2, "the price row gains the was-price placeholder")
        XCTAssertEqual(priceRow.children.last?.hidden, true, "the inserted was-price is hidden")
    }
}
