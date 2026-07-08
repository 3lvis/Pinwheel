import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class TokenMappingTests: XCTestCase {

    func testPrimaryStyleFillsActionTextAndTextsPrimaryBackground() {
        XCTAssertEqual(PinButton.Style.primary.fillToken, .actionText)
        XCTAssertEqual(PinButton.Style.primary.textColorToken, .primaryBackground)
        XCTAssertEqual(PinButton.Style.primary.captureFillToken, "actionText")
        XCTAssertEqual(PinButton.Style.primary.captureTextColorToken, "primaryBackground")
    }

    func testSecondaryStyleFillsSecondaryBackgroundAndTextsPrimaryText() {
        XCTAssertEqual(PinButton.Style.secondary.fillToken, .secondaryBackground)
        XCTAssertEqual(PinButton.Style.secondary.textColorToken, .primaryText)
        XCTAssertEqual(PinButton.Style.secondary.captureFillToken, "secondaryBackground")
        XCTAssertEqual(PinButton.Style.secondary.captureTextColorToken, "primaryText")
    }

    func testTertiaryStyleHasNoFillAndTextsSecondaryText() {
        XCTAssertNil(PinButton.Style.tertiary.fillToken)
        XCTAssertEqual(PinButton.Style.tertiary.textColorToken, .secondaryText)
        XCTAssertNil(PinButton.Style.tertiary.captureFillToken)
        XCTAssertEqual(PinButton.Style.tertiary.captureTextColorToken, "secondaryText")
    }

    func testCustomStyleMapsToNoTokensButCarriesItsRawColors() {
        let style = PinButton.Style.custom(text: .red, background: .blue)
        XCTAssertNil(style.fillToken)
        XCTAssertNil(style.textColorToken)
        XCTAssertNil(style.captureFillToken)
        XCTAssertNil(style.captureTextColorToken)
        XCTAssertEqual(style.captureFillColor, .blue)
        XCTAssertEqual(style.captureTextColor, .red)
    }

    func testEachColorTokenCaptureNameEqualsItsRawValue() {
        XCTAssertEqual(PinColorToken.primaryText.rawValue, "primaryText")
        XCTAssertEqual(PinColorToken.secondaryText.rawValue, "secondaryText")
        XCTAssertEqual(PinColorToken.tertiaryText.rawValue, "tertiaryText")
        XCTAssertEqual(PinColorToken.actionText.rawValue, "actionText")
        XCTAssertEqual(PinColorToken.criticalText.rawValue, "criticalText")
        XCTAssertEqual(PinColorToken.primaryBackground.rawValue, "primaryBackground")
        XCTAssertEqual(PinColorToken.secondaryBackground.rawValue, "secondaryBackground")
        XCTAssertEqual(PinColorToken.actionBackground.rawValue, "actionBackground")
        XCTAssertEqual(PinColorToken.criticalBackground.rawValue, "criticalBackground")
    }

    func testLabelTextColorMapsEachRoleToItsToken() {
        XCTAssertEqual(PinLabel.TextColor.primary.token, .primaryText)
        XCTAssertEqual(PinLabel.TextColor.secondary.token, .secondaryText)
        XCTAssertEqual(PinLabel.TextColor.tertiary.token, .tertiaryText)
        XCTAssertEqual(PinLabel.TextColor.action.token, .actionText)
        XCTAssertEqual(PinLabel.TextColor.critical.token, .criticalText)
        XCTAssertNil(PinLabel.TextColor.custom(.red).token)

        XCTAssertEqual(PinLabel.TextColor.primary.captureTextColorToken, "primaryText")
        XCTAssertEqual(PinLabel.TextColor.secondary.captureTextColorToken, "secondaryText")
        XCTAssertEqual(PinLabel.TextColor.tertiary.captureTextColorToken, "tertiaryText")
        XCTAssertEqual(PinLabel.TextColor.action.captureTextColorToken, "actionText")
        XCTAssertEqual(PinLabel.TextColor.critical.captureTextColorToken, "criticalText")
        XCTAssertNil(PinLabel.TextColor.custom(.red).captureTextColorToken)
    }

}
