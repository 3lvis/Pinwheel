import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class OrderedForLayoutTests: XCTestCase {
    private func box(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> PinDisplayListCapture.Box {
        PinDisplayListCapture.Box(DisplayLeaf(frame: CGRect(x: x, y: y, width: w, height: h), kind: .transparent))
    }

    // A stepper row: a full-height value between a short minus bar and a plus glyph. The glyphs share a
    // vertical centre but differ in top-edge y by more than a few points, so ordering by top-edge y wrongly
    // reads them as stacked and scrambles them (− 1 + → 1 + −). Ordering must key on the vertical centre.
    func testMixedHeightRowOrdersLeftToRightByCentre() {
        let minus = box(x: 295.7, y: 59.7, w: 14, h: 2)
        let value = box(x: 323.7, y: 50.3, w: 8, h: 20)
        let plus = box(x: 346, y: 53.7, w: 14, h: 14)
        let ordered = PinDisplayListCapture.orderedForLayout([value, plus, minus])
        XCTAssertEqual(ordered.map { $0.leaf.frame.minX }, [295.7, 323.7, 346],
                       "elements sharing a vertical centre order left-to-right, regardless of differing heights/top-edges")
    }
}
