import XCTest
import CoreGraphics
@testable import Pinwheel

// Guards the v7 corruption (Fixtures/apple-controls-v7-corruption.png): a capture triggered from the
// catalog cropped the ambient key window and assigned catalog rows to the component's control leaves by
// blind vertical order. Live crops are now assigned only when they share the component's vertical rhythm
// (a consistent shift), so controls from another on-screen surface are rejected.
@MainActor
final class ControlCropMatchTests: XCTestCase {
    // The Apple-controls control leaves, as the capture host lays them out (from a real capture).
    private let leaves: [(index: Int, frame: CGRect)] = [
        (index: 3, frame: CGRect(x: 16, y: 178, width: 61, height: 29)),
        (index: 5, frame: CGRect(x: 16, y: 239, width: 370, height: 32)),
        (index: 7, frame: CGRect(x: 16, y: 304, width: 370, height: 31)),
    ]

    func testControlCropsRejectForeignControls() {
        // Controls found in the key window but from another surface (the catalog): same count, but their
        // positions don't share the component's rhythm, so the per-leaf shift is inconsistent.
        let foreign: [(frame: CGRect, image: String)] = [
            (frame: CGRect(x: 16, y: 300, width: 300, height: 44), image: "catalog-row-a"),
            (frame: CGRect(x: 16, y: 520, width: 300, height: 44), image: "catalog-row-b"),
            (frame: CGRect(x: 16, y: 590, width: 300, height: 44), image: "catalog-row-c"),
        ]
        XCTAssertTrue(PinDisplayList.matchedControlCrops(wideLeaves: leaves, crops: foreign).isEmpty,
                      "controls from another on-screen surface must not be assigned to this component's leaves")
    }

    func testControlCropsAssignWhenSharingTheComponentsRhythm() {
        // The component captured full-screen (the sweep): each control sits at its leaf position shifted
        // by a constant (here +8, as observed live), so the crops are assigned by vertical order.
        let aligned: [(frame: CGRect, image: String)] = [
            (frame: CGRect(x: 16, y: 178 + 8, width: 63, height: 29), image: "toggle"),
            (frame: CGRect(x: 16, y: 239 + 8, width: 370, height: 33), image: "segmented"),
            (frame: CGRect(x: 16, y: 304 + 8, width: 370, height: 31), image: "slider"),
        ]
        let matches = PinDisplayList.matchedControlCrops(wideLeaves: leaves, crops: aligned)
        XCTAssertEqual(matches[3]?.image, "toggle")
        XCTAssertEqual(matches[5]?.image, "segmented")
        XCTAssertEqual(matches[7]?.image, "slider")
        // The crop frame comes back so the leaf can size to the real control bounds (SwiftUI undersizes
        // a platform view), rather than the placeholder frame that would crop it under FILL.
        XCTAssertEqual(matches[3]?.frame.width, 63)
    }
}
