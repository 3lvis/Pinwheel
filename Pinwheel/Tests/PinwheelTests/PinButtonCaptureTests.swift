import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class PinButtonCaptureTests: XCTestCase {
    // Guards the collapse regression: distinct-looking buttons must get distinct capture names, or
    // they share one Figma master and inherit its children/state (the "Saving lost its spinner",
    // "Save wasn't dimmed" bugs). `disabled` is env-driven so it's render-only, not covered here.
    func testCaptureNameEncodesVariantIconSymbolLoading() {
        XCTAssertEqual(PinButton("Save").captureName, "PinButton-primary")
        XCTAssertEqual(PinButton("Save").style(.secondary).captureName, "PinButton-secondary")
        XCTAssertEqual(PinButton("Save").style(.tertiary).captureName, "PinButton-tertiary")
        XCTAssertEqual(
            PinButton("x").style(.custom(text: .green, background: .red)).captureName,
            "PinButton-custom"
        )
        XCTAssertEqual(PinButton("Continue", systemImage: "arrow.right").captureName, "PinButton-primary-icon")
        XCTAssertEqual(PinButton(systemImage: "arrow.right").captureName, "PinButton-primary-icon-symbol")
        XCTAssertEqual(PinButton("Saving").loading().captureName, "PinButton-primary-loading")
        XCTAssertEqual(
            PinButton("Saving", systemImage: "arrow.right").style(.secondary).loading().captureName,
            "PinButton-secondary-icon-loading"
        )
    }

    // Guards the dropped-custom-color regression: `.custom` carries raw colors (no token),
    // token styles carry a token name (no raw color).
    func testCustomStyleCarriesRawColorsAndTokenStylesDoNot() {
        let custom = PinButton.Style.custom(text: .green, background: .red)
        XCTAssertNil(custom.captureFillToken)
        XCTAssertNil(custom.captureTextColorToken)
        XCTAssertNotNil(custom.captureFillColor)
        XCTAssertNotNil(custom.captureTextColor)

        XCTAssertEqual(PinButton.Style.primary.captureFillToken, "actionText")
        XCTAssertEqual(PinButton.Style.primary.captureTextColorToken, "primaryBackground")
        XCTAssertNil(PinButton.Style.primary.captureFillColor)
        XCTAssertEqual(PinButton.Style.secondary.captureFillToken, "secondaryBackground")
        XCTAssertNil(PinButton.Style.tertiary.captureFillToken)
    }

    // Guards the tertiary-underline capture.
    func testLabelUnderlinesTertiaryOnly() {
        XCTAssertFalse(PinButton("x").labelStyle.underline)
        XCTAssertFalse(PinButton("x").style(.secondary).labelStyle.underline)
        XCTAssertTrue(PinButton("x").style(.tertiary).labelStyle.underline)
    }
}
