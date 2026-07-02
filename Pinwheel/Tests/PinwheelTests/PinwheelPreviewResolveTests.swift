import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class PinwheelPreviewResolveTests: XCTestCase {
    private var sections: [PinwheelSection] {
        [
            PinwheelSection("Components") {
                PinwheelItem("Button") { SwiftUI.Text("") }
                PinwheelItem("Label") { SwiftUI.Text("") }
            },
            PinwheelSection("Screens") {
                PinwheelItem("Button") { SwiftUI.Text("") }
            }
        ]
    }

    func testResolvesABareItemID() {
        XCTAssertEqual(PinwheelPreview.resolve(id: "label", in: sections)?.item.id, "label")
    }

    func testQualifiedIDDisambiguatesItemsSharingAnID() {
        // "button" exists in both sections; the qualified form picks the section.
        XCTAssertEqual(PinwheelPreview.resolve(id: "screens/button", in: sections)?.section.id, "screens")
        XCTAssertEqual(PinwheelPreview.resolve(id: "components/button", in: sections)?.section.id, "components")
    }

    func testUnknownIDResolvesToNil() {
        XCTAssertNil(PinwheelPreview.resolve(id: "nope", in: sections))
        XCTAssertNil(PinwheelPreview.resolve(id: "components/nope", in: sections))
    }

    func testWhitespaceIsTrimmed() {
        XCTAssertEqual(PinwheelPreview.resolve(id: "  label  ", in: sections)?.item.id, "label")
    }
}
