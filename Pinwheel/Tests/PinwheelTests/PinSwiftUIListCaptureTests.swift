import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class PinSwiftUIListCaptureTests: XCTestCase {
    private struct ListScreen: SwiftUI.View {
        var body: some SwiftUI.View {
            List { ForEach(1...12, id: \.self) { SwiftUI.Text("Row \($0)") } }
        }
    }


    // A SwiftUI List hides each row behind a CellHostingView; capture must force-realize the backing
    // collection and read each cell's own DisplayList so rows land as editable text, not a flat image.
    func testListRowsCaptureAsEditableText() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 800))
        let controller = UIHostingController(rootView: ListScreen())
        window.rootViewController = controller
        window.isHidden = false
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()

        let document = try XCTUnwrap(
            PinSwiftUIListCapture.document(name: "List", size: CGSize(width: 402, height: 800), screenHeight: 778, liveHost: controller.view),
            "a SwiftUI List should capture its rows, not return nil"
        )
        var texts: [String] = []
        func collect(_ node: FigmaNode) { texts += (node.texts?.map { $0.text } ?? []); node.children.forEach(collect) }
        collect(document.root)
        XCTAssertTrue(texts.contains("Row 1"), "row text must capture as editable text nodes")
        XCTAssertTrue(texts.contains("Row 12"), "every realized row captures, not just the visible viewport")
        withExtendedLifetime(window) {}
    }
}
