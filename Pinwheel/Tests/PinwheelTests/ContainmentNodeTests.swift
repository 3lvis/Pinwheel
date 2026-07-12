import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class ContainmentNodeTests: XCTestCase {
    private func text(_ string: String, _ frame: CGRect) -> DisplayLeaf {
        DisplayLeaf(frame: frame, kind: .text(string, font: .systemFont(ofSize: 14), color: .black, underline: false, strikethrough: false, alignment: .natural))
    }

    private func allText(_ node: FigmaNode) -> [String] {
        (node.texts?.map { $0.text } ?? []) + node.children.flatMap { allText($0) }
    }

    // A raw List cell's whole row lives in one CellHostingView DisplayList. Building it via containment
    // (no SwiftUI value to reflect) must keep EVERY leaf — the earlier path lost all but one text per row.
    func testContainmentNodeKeepsEveryTextLeaf() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 402, height: 100))
        let leaves = [
            text("Wireless Earbuds Pro", CGRect(x: 80, y: 20, width: 180, height: 20)),
            text("SALE", CGRect(x: 270, y: 20, width: 40, height: 16)),
            text("$129", CGRect(x: 80, y: 48, width: 40, height: 20)),
            text("$159", CGRect(x: 128, y: 48, width: 40, height: 16)),
            text("1", CGRect(x: 350, y: 34, width: 12, height: 20)),
        ]
        let node = PinDisplayListCapture.containmentNode(leaves: leaves, host: host)
        XCTAssertNotNil(node)
        XCTAssertEqual(Set(allText(node ?? FigmaNode(tag: "frame", x: 0, y: 0, w: 0, h: 0, children: []))),
                       ["Wireless Earbuds Pro", "SALE", "$129", "$159", "1"],
                       "every text leaf survives the containment build")
    }

    // A lone leaf's frame equals the union bounds; the seeded root must still enclose it, or the single
    // text is orphaned and lost (the regression a plain "Row N" List row hit).
    func testContainmentNodeKeepsALoneLeaf() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 402, height: 44))
        let leaf = text("Row 1", CGRect(x: 16, y: 12, width: 60, height: 20))
        let node = PinDisplayListCapture.containmentNode(leaves: [leaf], host: host)
        XCTAssertEqual(allText(node ?? FigmaNode(tag: "frame", x: 0, y: 0, w: 0, h: 0, children: [])), ["Row 1"])
    }
}
