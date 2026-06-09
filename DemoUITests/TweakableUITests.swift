import XCTest

/// Exercises the Tweakable examples through the deep-link preview
/// (`-PinwheelPreview <id>`): opening the playground settings and choosing an
/// option should mutate the example's content. Covers both the SwiftUI
/// `pinwheelTweaks` path and the UIKit `Tweakable` → `PinwheelTweak` bridge.
final class TweakableUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ previewID: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-PinwheelPreview", previewID]
        app.launch()
        return app
    }

    private func openSettings(in app: XCUIApplication) {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10), "settings (wrench) button should exist")
        settings.tap()
    }

    // MARK: - SwiftUI pinwheelTweaks

    @MainActor
    func testSwiftUIActionTweakUpdatesContent() {
        let app = launch("tweakable")
        openSettings(in: app)

        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: 10), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: 10),
                      "Choosing an action tweak should update the example label")
    }

    @MainActor
    func testSwiftUIToggleTweakUpdatesContent() {
        let app = launch("tweakable")
        openSettings(in: app)

        let option3 = app.switches["Option 3, Toggle-backed option"]
        XCTAssertTrue(option3.waitForExistence(timeout: 10), "Option 3 toggle should be listed")
        // The row is a single combined element; tapping its center hits the label,
        // so tap the switch control on the trailing edge to actually flip it.
        option3.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        // Dismiss the sheet to read the label underneath.
        app.buttons["Done"].tap()

        XCTAssertTrue(app.staticTexts["Option 3 is on"].waitForExistence(timeout: 10),
                      "Toggling a bool tweak should update the example label")
    }

    @MainActor
    func testSwiftUISecondActionTweakStillUpdatesContent() {
        let app = launch("tweakable")

        openSettings(in: app)
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: 10))
        option1.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: 10))

        openSettings(in: app)
        // The row carries a description, so its accessibility label is the
        // combined "title, description".
        let option2 = app.buttons["Option 2, Description 2"]
        XCTAssertTrue(option2.waitForExistence(timeout: 10), "Option 2 should still be listed on reopen")
        option2.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 2"].waitForExistence(timeout: 10),
                      "A second tweak selection should still update the example label")
    }

    // MARK: - Catalog navigation (the real user path: nested presentation)

    @MainActor
    func testCatalogTweakableActionUpdatesContent() {
        let app = XCUIApplication()
        app.launch()

        // A previously presented item may be restored on launch; dismiss it.
        let close = app.buttons["pinwheel.close"]
        if close.waitForExistence(timeout: 2) {
            close.tap()
        }

        XCTAssertTrue(app.buttons["pinwheel.sectionPicker"].waitForExistence(timeout: 10),
                      "section picker should exist")

        // Switch to the Components section unless we're already there (in which
        // case the Tweakable row is already on screen). Opening the picker only
        // when needed avoids the "Components" label colliding with the picker
        // button when that section is already selected.
        let tweakable = app.buttons["Tweakable"]
        if !tweakable.waitForExistence(timeout: 2) {
            app.buttons["pinwheel.sectionPicker"].tap()
            let components = app.sheets.buttons["Components"]
            XCTAssertTrue(components.waitForExistence(timeout: 10), "Components section should be listed")
            components.tap()
            XCTAssertTrue(tweakable.waitForExistence(timeout: 10), "Tweakable item should be listed")
        }
        tweakable.tap()

        openSettings(in: app)
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: 10), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: 10),
                      "Choosing a tweak from the catalog (nested presentation) should update the label")
    }

    // MARK: - UIKit Tweakable bridge

    @MainActor
    func testUIKitActionTweakUpdatesContent() {
        let app = launch("uikit-tweakable")
        openSettings(in: app)

        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: 10), "bridged Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Choosen Option 1!\n\nYou can drag the button too :D"].waitForExistence(timeout: 10),
                      "A bridged UIKit action tweak should update the example label")
    }
}
