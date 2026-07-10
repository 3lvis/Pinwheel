import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class PinCaptureTokensTests: XCTestCase {
    override func tearDown() {
        PinCaptureTokens.current = .pinwheel
        super.tearDown()
    }

    // A consumer's own color must bind to the consumer's own token name — the engine can't be hardwired to
    // Pinwheel's palette.
    func testCustomColorRegistryBindsConsumerTokenName() {
        let brand = UIColor(red: 0.90, green: 0.20, blue: 0.50, alpha: 1)
        PinCaptureTokens.current = PinCaptureTokens(
            colors: [PinCaptureTokens.ColorToken(name: "brand/pink", light: brand, dark: brand)],
            spacings: [], radii: [], systemFontFamily: "SF Pro Rounded"
        )
        XCTAssertEqual(PinDisplayListCapture.tokenName(for: brand), "brand/pink")
    }

    // A consumer's spacing scale (indexed names, e.g. space-3 = 12) must bind, not Pinwheel's.
    func testCustomSpacingRegistryBindsConsumerName() {
        PinCaptureTokens.current = PinCaptureTokens(
            colors: [], spacings: [PinCaptureTokens.FloatToken(name: "space-3", value: 12)], radii: [], systemFontFamily: "X"
        )
        XCTAssertEqual(PinFloatTokens.spacingName(for: 12), "space-3")
    }

    // A custom (non-system) font must capture its real family, so a consumer's brand font imports correctly
    // instead of the hardcoded system design name.
    func testCapturedTextUsesTheActualFontFamily() throws {
        let georgia = try XCTUnwrap(UIFont(name: "Georgia", size: 16))
        let font = PinDisplayListCapture.figmaFont(georgia, color: .black, underline: false)
        XCTAssertEqual(font.family, "Georgia", "a custom font captures its real family, not the system design name")
    }

    // Regression: the default registry still binds Pinwheel's own tokens.
    func testDefaultRegistryStillBindsPinwheelTokens() {
        let actionBackground = UIColor(PinColorToken.actionBackground.color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(PinDisplayListCapture.tokenName(for: actionBackground), "actionBackground")
    }
}
