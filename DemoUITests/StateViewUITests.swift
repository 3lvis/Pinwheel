import XCTest

/// Exercises the StateView through the deep-link preview (`-PinwheelPreview <id>`),
/// covering interactions that screenshots can't verify headlessly: opening the
/// playground settings, switching to the failed state via a tweak, and tapping
/// the failed-state action ("Retry").
final class StateViewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ previewID: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-PinwheelPreview", previewID]
        app.launch()
        return app
    }

    /// Opens the playground settings and selects the "Failed" tweak, leaving the
    /// component in its failed state with the action button visible.
    private func selectFailedState(in app: XCUIApplication) {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10), "settings (wrench) button should exist")
        settings.tap()

        let failed = app.buttons["Failed"]
        XCTAssertTrue(failed.waitForExistence(timeout: 10), "Failed tweak should be listed in the settings sheet")
        failed.tap()
    }

    // MARK: - SwiftUI PinStateView

    @MainActor
    func testSwiftUIStateViewRendersDefaultEmptyState() {
        let app = launch("state-view")
        XCTAssertTrue(app.staticTexts["Ready to Move?"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testSwiftUIStateViewRetryTriggersLoading() {
        let app = launch("state-view")
        selectFailedState(in: app)

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: 10))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 10),
                      "Tapping Retry should switch the SwiftUI state view to loading")
    }

    // MARK: - UIKit shell (UIKitPinStateView over PinStateView)

    @MainActor
    func testUIKitStateViewBridgesTweaksAndRetry() {
        let app = launch("uikit-state-view")
        selectFailedState(in: app)

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: 10))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: 10),
                      "Tapping Retry should fire the delegate and switch the UIKit state view to loading")
    }
}
