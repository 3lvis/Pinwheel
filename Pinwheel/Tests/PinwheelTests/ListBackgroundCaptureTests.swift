import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class ListBackgroundCaptureTests: XCTestCase {
    // A `.plain` List's collection is transparent, so the captured screen would have no background. The
    // capture falls back to the opaque surface rendered behind it — the first opaque backgroundColor up
    // the superview chain, which is what the list is visually drawn on.
    func testOpaqueBackgroundFindsSurfaceBehindTransparentView() {
        let surface = UIColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1)
        let root = UIView(); root.backgroundColor = surface
        let transparent = UIView(); transparent.backgroundColor = .clear
        let collection = UIView()
        root.addSubview(transparent); transparent.addSubview(collection)
        XCTAssertEqual(PinSwiftUIListCapture.opaqueBackground(above: collection), surface,
                       "the screen background falls back to the opaque surface behind a transparent collection")
    }

    // A fully transparent chain has no surface to fall back to — return nil rather than a bogus fill.
    func testOpaqueBackgroundIsNilWhenNothingBehindIsOpaque() {
        let root = UIView(); root.backgroundColor = .clear
        let collection = UIView()
        root.addSubview(collection)
        XCTAssertNil(PinSwiftUIListCapture.opaqueBackground(above: collection))
    }
}
