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

    // Rows that differ only by a pill's fill COLOUR (a bonus chip vs a warning chip) group as one component
    // with the fill overridden per instance — a Figma instance can override a fill, so colour isn't a
    // structural difference.
    func testSameStructureRowsWithDifferentFillsGroup() {
        func pill(_ token: String) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 40, h: 20, fill: RGBA(r: 0, g: 0, b: 0, a: 1), fillToken: token, children: [text()])
        }
        func row(_ token: String) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 80, children: [pill(token), text()])
        }
        let parent = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 240,
                               children: [row("actionBackground"), row("primaryBackground"), row("criticalBackground")])
        let result = PinDisplayListCapture.componentizeRepeatedChildren(parent)
        let keys = result.children.map { $0.component }
        XCTAssertTrue(keys.allSatisfy { $0 != nil }, "every row is part of the component")
        XCTAssertEqual(Set(keys.compactMap { $0 }).count, 1, "same-structure rows group even when a pill's fill colour differs")
    }

    // Rows whose chip differs only in WIDTH (a short "Bonus" vs a long "Not delivered") group — a chip hugs
    // its overridable text, so its size varies per instance and mustn't split the template.
    func testSameStructureRowsWithDifferentChipWidthsGroup() {
        func chip(_ width: Double) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: width, h: 20, fill: RGBA(r: 0, g: 0, b: 0, a: 1), fillToken: "actionBackground", children: [text()])
        }
        func row(_ width: Double) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 80, children: [chip(width), text()])
        }
        let parent = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 240, children: [row(40), row(64), row(96)])
        let result = PinDisplayListCapture.componentizeRepeatedChildren(parent)
        XCTAssertEqual(Set(result.children.compactMap { $0.component }).count, 1,
                       "rows whose chip differs only in width group as one component")
    }

    // A row carrying TWO chips is a SUPERSET of the one-chip rows. The master must be the superset (a Figma
    // instance can hide a layer but not add one), so the one-chip rows join as instances that hide the second
    // chip. Mirrors Order Summary, where one product has both a Bonus and a discount pill among rows with one.
    func testSupersetRowIsMasterAndSubsetRowsHideTheExtraChip() {
        func chip(_ token: String) -> FigmaNode {
            FigmaNode(tag: "frame", x: 0, y: 0, w: 40, h: 20, fill: RGBA(r: 0, g: 0, b: 0, a: 1), fillToken: token, children: [text()])
        }
        func row(_ chips: [FigmaNode]) -> FigmaNode {
            let pillRow = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 20, children: chips)
            return FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 80, children: [pillRow, text()])
        }
        let parent = FigmaNode(tag: "frame", x: 0, y: 0, w: 300, h: 320, children: [
            row([chip("actionBackground")]),
            row([chip("primaryBackground")]),
            row([chip("actionBackground"), chip("criticalBackground")]),
            row([chip("primaryBackground")]),
        ])
        let result = PinDisplayListCapture.componentizeRepeatedChildren(parent)
        let keys = result.children.map { $0.component }
        XCTAssertTrue(keys.allSatisfy { $0 != nil }, "every row joins the component")
        XCTAssertEqual(Set(keys.compactMap { $0 }).count, 1, "one-chip and two-chip rows share ONE component")

        let oneChipPillRow = result.children[0].children[0]
        XCTAssertEqual(oneChipPillRow.children.count, 2, "the one-chip row gains the second-chip placeholder")
        XCTAssertEqual(oneChipPillRow.children.last?.hidden, true, "the inserted second chip is hidden")

        let twoChipPillRow = result.children[2].children[0]
        XCTAssertEqual(twoChipPillRow.children.count, 2)
        XCTAssertNotEqual(twoChipPillRow.children.last?.hidden, true, "the superset row keeps both chips visible")
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

        let noSale = result.children[2]
        let titleRow = noSale.children[0]
        let priceRow = noSale.children[1]
        XCTAssertEqual(titleRow.children.count, 2, "the title row gains the SALE pill placeholder")
        XCTAssertEqual(titleRow.children.last?.hidden, true, "the inserted SALE pill is hidden")
        XCTAssertEqual(priceRow.children.count, 2, "the price row gains the was-price placeholder")
        XCTAssertEqual(priceRow.children.last?.hidden, true, "the inserted was-price is hidden")
    }
}
