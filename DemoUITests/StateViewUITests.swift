import XCTest

/// Exercises the StateView through the deep-link preview (`-PinwheelPreview <id>`),
/// covering interactions that screenshots can't verify headlessly: opening the
/// playground settings, switching to the failed state via a tweak, and tapping
/// the failed-state action ("Retry").
final class StateViewUITests: XCTestCase {
    private var app: XCUIApplication!

    /// Failure ceiling for element waits — `waitForExistence` returns as soon as
    /// the element appears, so this only bounds how long a *failing* test waits.
    /// 5s is the community default; this suite is local, animation-free and
    /// network-free, so elements appear well within it.
    private let defaultTimeout: TimeInterval = 5

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // -UITesting makes the app clear persisted catalog state and disable
        // animations on launch (see DemoApp); tests add -PinwheelPreview as needed.
        app.launchArguments = ["-UITesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launchPreview(_ previewID: String) {
        app.launchArguments += ["-PinwheelPreview", previewID]
        app.launch()
    }

    /// Opens the playground settings and selects the "Failed" tweak, leaving the
    /// component in its failed state with the action button visible.
    private func selectFailedState() {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: defaultTimeout), "settings (wrench) button should exist")
        settings.tap()

        let failed = app.buttons["Failed"]
        XCTAssertTrue(failed.waitForExistence(timeout: defaultTimeout), "Failed tweak should be listed in the settings sheet")
        failed.tap()
    }

    // MARK: - SwiftUI PinStateView

    @MainActor
    func testSwiftUIStateViewRendersDefaultEmptyState() {
        launchPreview("swiftui-stateview")
        XCTAssertTrue(app.staticTexts["Ready to Move?"].waitForExistence(timeout: defaultTimeout))
    }

    @MainActor
    func testSwiftUIStateViewRetryTriggersLoading() {
        launchPreview("swiftui-stateview")
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should switch the SwiftUI state view to loading")
    }

    // MARK: - UIKit shell (UIKitPinStateView over PinStateView)

    @MainActor
    func testUIKitStateViewBridgesTweaksAndRetry() {
        launchPreview("uikit-stateview")
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should fire the delegate and switch the UIKit state view to loading")
    }

    // MARK: - UIKit view-controller host (UIKitPinStateView inside a UIViewController)

    /// Same contract as the `view:`-hosted case above, but through the
    /// `PinwheelItem(viewController:)` path — guards that a `UIViewController`'s
    /// `Tweakable` tweaks bridge into the settings sheet and that the retry tap
    /// drives the live (on-screen) instance, not an off-screen copy.
    @MainActor
    func testUIKitViewControllerStateViewBridgesTweaksAndRetry() {
        launchPreview("uikit-viewcontroller")
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should fire the delegate and switch the view-controller-hosted state view to loading")
    }
}
