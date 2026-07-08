import XCTest
import CoreGraphics
@testable import Pinwheel

@MainActor
final class ControlCropMatchTests: XCTestCase {
    func testControlCropsAssignByVerticalOrderEvenWhenRowSpacingDrifts() {
        let leaves: [(index: Int, frame: CGRect)] = [
            (index: 2, frame: CGRect(x: 16, y: 250, width: 51, height: 31)),
            (index: 5, frame: CGRect(x: 16, y: 303, width: 51, height: 31)),
            (index: 8, frame: CGRect(x: 16, y: 355, width: 51, height: 31)),
        ]
        let crops: [(frame: CGRect, image: String)] = [
            (frame: CGRect(x: 16, y: 407, width: 61, height: 28), image: "off"),
            (frame: CGRect(x: 16, y: 473, width: 61, height: 28), image: "off2"),
            (frame: CGRect(x: 16, y: 539, width: 61, height: 28), image: "on"),
        ]
        let matches = PinDisplayList.matchedControlCrops(wideLeaves: leaves, crops: crops)
        XCTAssertEqual(matches[2]?.image, "off")
        XCTAssertEqual(matches[8]?.image, "on")
        XCTAssertEqual(matches[2]?.frame.width, 61)
    }

    func testNoCropsAssignedWhenCountsDiffer() {
        let leaves: [(index: Int, frame: CGRect)] = [(index: 0, frame: CGRect(x: 0, y: 0, width: 60, height: 30))]
        XCTAssertTrue(PinDisplayList.matchedControlCrops(wideLeaves: leaves, crops: []).isEmpty)
    }
}
