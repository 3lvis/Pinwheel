import XCTest
import SwiftUI
@testable import Pinwheel

@MainActor
final class PinwheelTweakTests: XCTestCase {
    func testActionTweakRunsItsClosure() {
        var ran = false
        PinwheelTweak("Option", action: { ran = true }).applyAsPreviewVariant()
        XCTAssertTrue(ran)
    }

    func testToggleTweakIsForcedOnAsPreviewVariant() {
        var value = false
        let binding = Binding(get: { value }, set: { value = $0 })
        PinwheelTweak("Option", isOn: binding).applyAsPreviewVariant()
        XCTAssertTrue(value, "applyAsPreviewVariant turns a toggle on, never off")
    }

    func testTextTweakBridgesToAnActionThatRuns() {
        var ran = false
        let bridged = PinwheelTweak(TextTweak(title: "Option", action: { ran = true }))
        XCTAssertNotNil(bridged)
        bridged?.applyAsPreviewVariant()
        XCTAssertTrue(ran)
    }

    func testBoolTweakBridgesToAToggleControl() {
        let bridged = PinwheelTweak(BoolTweak(title: "Option", isOn: false, action: { _ in }))
        guard case .toggle? = bridged?.control else {
            return XCTFail("a BoolTweak should bridge to a toggle control")
        }
    }

    func testBoolStoreForwardsToTheUIKitAction() {
        var received: Bool?
        let store = PinwheelTweakBoolStore(BoolTweak(title: "Option", isOn: false, action: { received = $0 }))
        store.set(true)
        XCTAssertEqual(received, true, "flipping the bridged value forwards to the UIKit tweak's action")
    }

    func testUnknownTweakKindBridgesToNil() {
        struct CustomTweak: Tweak {
            var title = "Custom"
            var description: String?
        }
        XCTAssertNil(PinwheelTweak(CustomTweak()))
    }
}
