import XCTest
import DemoCatalog

/// App-layer wiring the unit layer can't reach: `PinStateView`'s failed-state
/// action button firing and the view transitioning, across SwiftUI and the two
/// UIKit hosting seams (`view:` and `viewController:`). The state values are data;
/// only the button → transition → render glue needs a running UI.
final class StateViewUITests: XCTestCase {
    private var app: XCUIApplication!

    // Only bounds how long a failing test waits — waitForExistence returns as
    // soon as the element appears.
    private let defaultTimeout: TimeInterval = 5

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launchPreview(_ component: Catalog, _ tag: PinTag) {
        app.launchArguments += ["-PinwheelPreview", component.id(tag)]
        app.launch()
    }

    private func selectFailedState() {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: defaultTimeout), "settings (wrench) button should exist")
        settings.tap()

        let failed = app.buttons["Failed"]
        XCTAssertTrue(failed.waitForExistence(timeout: defaultTimeout), "Failed tweak should be listed in the settings sheet")
        failed.tap()
    }

    // KEEP: app-layer wiring — the SwiftUI failed-state action button fires and
    // PinStateView transitions to loading.
    @MainActor
    func testSwiftUIStateViewRetryTriggersLoading() {
        launchPreview(.stateView, .swiftUI)
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should switch the SwiftUI state view to loading")
    }

    // KEEP: app-layer wiring — the UIPinStateView shell hosts PinStateView and
    // bridges the retry action to its delegate.
    @MainActor
    func testUIKitStateViewBridgesTweaksAndRetry() {
        launchPreview(.stateView, .uiKit)
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should fire the delegate and switch the UIKit state view to loading")
    }

    // KEEP: app-layer wiring — the `viewController:` hosting seam bridges Tweakable
    // into the sheet and drives the live on-screen instance, not an off-screen copy.
    @MainActor
    func testUIKitViewControllerStateViewBridgesTweaksAndRetry() {
        launchPreview(.viewController, .uiKit)
        selectFailedState()

        XCTAssertTrue(app.staticTexts["Oops!"].waitForExistence(timeout: defaultTimeout))
        let retry = app.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: defaultTimeout))
        retry.tap()

        XCTAssertTrue(app.staticTexts["Loading..."].waitForExistence(timeout: defaultTimeout),
                      "Tapping Retry should fire the delegate and switch the view-controller-hosted state view to loading")
    }
}
