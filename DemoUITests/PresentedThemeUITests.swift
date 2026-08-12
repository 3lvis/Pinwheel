import DemoCatalog
import XCTest

final class PresentedThemeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testASheetOverAPresentedItemRendersInTheSelectedTheme() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-PinwheelPreview", Catalog.stateView.id(.swiftUI), "-PinwheelPreviewTheme", "Ember"]
        app.launch()

        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()

        XCTAssertTrue(
            app.staticTexts["pinwheel.settings.theme.Ember"].waitForExistence(timeout: 5),
            "a sheet takes its traits from the window, not from the view that presented it, so the catalog writes the theme onto the window — without that this sheet falls back to the standard theme"
        )
    }
}
