import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class TweakChainTests: XCTestCase {
    private struct TweakableDemo: SwiftUI.View {
        @SwiftUI.State private var chosen = "Nothing chosen."

        var body: some SwiftUI.View {
            PinLabel(chosen)
                .pinwheelTweaks {
                    PinwheelTweak("Option 1") { chosen = "You chose Option 1." }
                    PinwheelTweak("Option 2") { chosen = "You chose Option 2." }
                }
        }
    }

    private func hostPlayground() -> (window: UIWindow, chrome: PinwheelChrome) {
        let chrome = PinwheelChrome()
        chrome.themes = [.standard]
        chrome.normalizeTheme()

        let item = PinwheelItem("Tweakable") { TweakableDemo() }
        let playground = PinwheelPlayground(
            item: item,
            selection: PinwheelSelection(sectionID: "components", itemID: item.id),
            onClose: {},
            previewMode: true
        )
        .environment(chrome)

        return (HostedView.window(showing: playground), chrome)
    }

    func testActivatingATweakUpdatesTheComponent() throws {
        let (window, chrome) = hostPlayground()
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertFalse(chrome.tweaks.isEmpty, "the component's tweaks should reach the chrome as a preference")

        chrome.showsTweaks = true
        _ = try HostedView.attachedTray(in: window)

        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Option 1", in: window),
            "the tweak should be listed in the tray and activatable"
        )
        XCTAssertTrue(
            HostedView.accessibilityLabels(in: window).contains("You chose Option 1."),
            "activating a tweak should re-render the component behind the tray"
        )
    }

    func testASecondTweakStillUpdatesTheComponentAfterTheTrayReopens() throws {
        let (window, chrome) = hostPlayground()
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        chrome.showsTweaks = true
        _ = try HostedView.attachedTray(in: window)
        XCTAssertTrue(HostedView.activateFirst(labelled: "Option 1", in: window))

        chrome.showsTweaks = false
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        chrome.showsTweaks = true
        _ = try HostedView.attachedTray(in: window)

        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Option 2", in: window),
            "the tweaks should survive the tray closing and the playground re-rendering"
        )
        XCTAssertTrue(
            HostedView.accessibilityLabels(in: window).contains("You chose Option 2."),
            "a second tweak selection should still update the component"
        )
    }
}
