import XCTest
import CoreGraphics
@testable import Pinwheel

// Live control crops are assigned to leaves by vertical order — the caller only passes crops when the
// component is the on-screen content, so top-to-bottom they line up. Order (not geometry) is what lets
// this survive a UITableView whose off-screen and on-screen row spacing differ. The v7 corruption
// (Fixtures/apple-controls-v7-corruption.png) is prevented upstream: a capture-on-view from the catalog
// passes no crops, so nothing foreign is ever assigned.
@MainActor
final class ControlCropMatchTests: XCTestCase {
    func testControlCropsAssignByVerticalOrderEvenWhenRowSpacingDrifts() {
        // Tableview switches: the UITableView lays rows out at a different spacing off-screen than
        // on-screen, so the per-row shift between leaf and crop drifts (here 157, 170, 184). Order-based
        // assignment still pairs them; a rigid-shift match would wrongly reject the whole set.
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
        // The crop frame comes back so the leaf sizes to the real control (61) not the placeholder (51).
        XCTAssertEqual(matches[2]?.frame.width, 61)
    }

    func testNoCropsAssignedWhenCountsDiffer() {
        // The catalog path passes no crops (liveControlsOnScreen == false); nothing is assigned.
        let leaves: [(index: Int, frame: CGRect)] = [(index: 0, frame: CGRect(x: 0, y: 0, width: 60, height: 30))]
        XCTAssertTrue(PinDisplayList.matchedControlCrops(wideLeaves: leaves, crops: []).isEmpty)
    }
}
