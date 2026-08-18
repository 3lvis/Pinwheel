import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class PresentedThemeTests: XCTestCase {
    private let ember = PinwheelTheme(
        name: "Ember",
        colors: DefaultColorProvider(),
        fonts: DefaultFontProvider()
    )

    private struct Fixture: SwiftUI.View {
        let theme: PinwheelTheme

        var body: some SwiftUI.View {
            Color.clear
                .background(PinwheelThemedWindow(theme: theme))
                .sheet(isPresented: .constant(true)) {
                    PinLabel("No tweaks")
                }
        }
    }

    func testASheetOverAPresentedItemResolvesTheThemeWrittenOnTheWindow() throws {
        let window = HostedView.window(showing: Fixture(theme: ember))
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        let sheet = try HostedView.attachedPresentation(in: window)

        XCTAssertEqual(
            sheet.view.traitCollection[PinwheelThemeTrait.self].name,
            ember.name,
            "a presentation takes its traits from the window, so the theme has to be written there — otherwise the sheet falls back to the standard theme"
        )
    }
}
