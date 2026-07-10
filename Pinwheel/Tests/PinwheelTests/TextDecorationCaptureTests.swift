import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class TextDecorationCaptureTests: XCTestCase {
    private func decorations(_ attributed: NSAttributedString) -> (underline: Bool, strikethrough: Bool) {
        guard case .text(_, _, _, let underline, let strikethrough, _) = PinDisplayList.textKind(from: attributed, fallback: nil) else {
            XCTFail("expected a text kind")
            return (false, false)
        }
        return (underline, strikethrough)
    }

    // A struck-through run (a "was" price) must carry its strikethrough into the IR, not import as plain text.
    func testStruckThroughRunCapturesStrikethrough() {
        let struck = NSAttributedString(string: "$4.99", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        XCTAssertTrue(decorations(struck).strikethrough)
    }

    // Plain text carries neither decoration.
    func testPlainRunHasNoDecorations() {
        let plain = NSAttributedString(string: "$4.99")
        XCTAssertFalse(decorations(plain).underline)
        XCTAssertFalse(decorations(plain).strikethrough)
    }

    // Underline and strikethrough are independent — a struck run isn't reported as underlined and vice versa.
    func testUnderlineAndStrikethroughAreIndependent() {
        let underlined = NSAttributedString(string: "Link", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        XCTAssertTrue(decorations(underlined).underline)
        XCTAssertFalse(decorations(underlined).strikethrough)
    }
}
