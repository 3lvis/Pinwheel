import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class PinwheelTweakTests: XCTestCase {
    func testActionTweakRunsItsClosure() {
        var ran = false
        PinwheelTweak("Option", action: { ran = true }).applyAsPreviewVariant(named: "Option")
        XCTAssertTrue(ran)
    }

    func testToggleTweakIsForcedOnAsPreviewVariant() {
        var value = false
        let binding = Binding(get: { value }, set: { value = $0 })
        PinwheelTweak("Option", isOn: binding).applyAsPreviewVariant(named: "Option")
        XCTAssertTrue(value, "applyAsPreviewVariant turns a toggle on, never off")
    }

    func testTextTweakBridgesToAnActionThatRuns() {
        var ran = false
        let bridged = PinwheelTweak(TextTweak(title: "Option", action: { ran = true }))
        XCTAssertNotNil(bridged)
        bridged?.applyAsPreviewVariant(named: "Option")
        XCTAssertTrue(ran)
    }

    func testBoolTweakBridgesToAToggleThatForwardsToTheUIKitAction() {
        var received: Bool?
        let bridged = PinwheelTweak(BoolTweak(title: "Option", isOn: false, action: { received = $0 }))
        guard case .toggle(let binding)? = bridged?.control else {
            return XCTFail("a BoolTweak should bridge to a toggle control")
        }
        binding.wrappedValue = true
        XCTAssertEqual(received, true, "flipping the bridged binding forwards to the UIKit tweak's action")
    }

    func testABridgedChoiceReportsTheOptionInForceRatherThanTheOneItWasBuiltWith() throws {
        var chosen = 0
        let bridged = try XCTUnwrap(PinwheelTweak(SelectTweak(
            title: "State",
            options: ["Loading", "Loaded"],
            chosenOption: { chosen },
            action: { chosen = $0 }
        )))

        bridged.applyAsPreviewVariant(named: "Loaded")

        XCTAssertEqual(chosen, 1, "choosing an option reaches the UIKit tweak's action")
        XCTAssertEqual(
            bridged.selectedOption,
            1,
            "a UIKit host never rebuilds the bridged tweak, so the option it reports has to be read live"
        )
    }

    func testUnknownTweakKindBridgesToNil() {
        struct CustomTweak: Tweak {
            var title = "Custom"
            var description: String?
        }
        XCTAssertNil(PinwheelTweak(CustomTweak()))
    }

    func testAnOptionListIsAddressableByEachOptionSoTheSweepStillCapturesEveryVariant() {
        var selection = 0
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let tweak = PinwheelTweak("State", options: ["Loading", "Loaded", "Empty"], selection: binding)

        XCTAssertEqual(
            tweak.previewVariantTitles,
            ["Loading", "Loaded", "Empty"],
            "The sweep enumerates variants by title, so an option list must offer its options rather than its own name"
        )
    }

    func testApplyingAPreviewVariantByNameSelectsThatOption() {
        var selection = 0
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let tweak = PinwheelTweak("State", options: ["Loading", "Loaded", "Empty"], selection: binding)

        tweak.applyAsPreviewVariant(named: "Empty")

        XCTAssertEqual(selection, 2)
    }

    func testAChangedSelectionMakesTheTweakUnequalSoThePreferencePropagates() {
        var selection = 0
        let binding = Binding(get: { selection }, set: { selection = $0 })
        let before = PinwheelTweak("State", options: ["Basket", "Simple"], selection: binding)

        selection = 1
        let after = PinwheelTweak("State", options: ["Basket", "Simple"], selection: binding)

        XCTAssertNotEqual(
            before,
            after,
            "onPreferenceChange only fires on inequality, so a tweak that ignores its selection leaves the tray showing a stale row"
        )
    }
}
