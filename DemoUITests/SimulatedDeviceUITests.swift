import XCTest
import DemoCatalog

final class SimulatedDeviceUITests: XCTestCase {
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

    private func openSettings() {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: defaultTimeout), "settings (wrench) button should exist")
        settings.tap()
    }





    // A UI test because the crash is SwiftUI's layout engine: a hosted playground stepping through
    // every device stays green even with the offending .animation(_:value:) restored.
    @MainActor
    func testSelectingSimulatedDeviceDoesNotCrash() {
        launchPreview(.tweakable, .swiftUI)
        openSettings()

        let deviceRow = app.buttons["pinwheel.device"]
        XCTAssertTrue(deviceRow.waitForExistence(timeout: defaultTimeout), "the Device row should be listed in settings")
        deviceRow.tap()

        let device = app.buttons["iPhone XS/11 Pro"]
        XCTAssertTrue(device.waitForExistence(timeout: defaultTimeout), "iPhone XS/11 Pro should be listed")
        device.tap()

        // Re-querying another row is the assertion: a crashed or hung app fails this query.
        XCTAssertTrue(app.buttons["iPhone SE (2nd & 3rd generation)"].waitForExistence(timeout: defaultTimeout),
                      "device list should stay responsive after selecting a device")
    }
}
