import XCTest
import DemoCatalog

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

    @MainActor
    func testSwiftUIStateViewRendersDefaultEmptyState() {
        launchPreview(.stateView, .swiftUI)
        XCTAssertTrue(app.staticTexts["Ready to Move?"].waitForExistence(timeout: defaultTimeout))
    }

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
