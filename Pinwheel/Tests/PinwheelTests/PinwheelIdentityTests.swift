import XCTest
import SwiftUI
@testable import Pinwheel

final class PinwheelIdentityTests: XCTestCase {
    func testGeneratedIDIsStableForEmojiOnlyTitle() {
        let first = PinwheelItem.generatedID(title: "🎉", tags: [])
        let second = PinwheelItem.generatedID(title: "🎉", tags: [])
        XCTAssertEqual(first, second, "a title that slugifies to empty must still produce a deterministic id")
        XCTAssertFalse(first.isEmpty, "id must never be empty — it keys persistence and deep-links")
    }

    func testGeneratedIDIsStableForPunctuationOnlyTitle() {
        XCTAssertEqual(
            PinwheelItem.generatedID(title: "•••"),
            PinwheelItem.generatedID(title: "•••")
        )
    }

    func testGeneratedIDFoldsTagsIntoTheTitleSlug() {
        XCTAssertEqual(PinwheelItem.generatedID(title: "DataSource TableView", tags: [.uiKit]), "uikit-datasource-tableview")
        XCTAssertEqual(PinwheelItem.generatedID(title: "Button", tags: [.swiftUI]), "swiftui-button")
    }

    @MainActor
    func testItemIDIsStableAcrossReadsForEmojiTitle() {
        let item = PinwheelItem("🎉") { SwiftUI.Text("x") }
        XCTAssertEqual(item.id, item.id, "a computed id must not change between reads")
    }

    @MainActor
    func testCaptureWorldFollowsHostedContentNotDisplayTag() {
        let figma = PinTag(rawValue: "Figma")
        let uiKitHosted = PinwheelItem("Grid", view: UIView.self).tags(figma)
        let swiftUIHosted = PinwheelItem("Card") { SwiftUI.Text("x") }.tags(figma)
        XCTAssertTrue(uiKitHosted.isUIKitHosted, "a view:-hosted item captures via the UIKit engine regardless of its display tag")
        XCTAssertFalse(swiftUIHosted.isUIKitHosted, "a SwiftUI content: item captures via the DisplayList engine regardless of its display tag")
    }
}
