import XCTest

/// Exercises the Tweakable examples through the deep-link preview
/// (`-PinwheelPreview <id>`): opening the playground settings and choosing an
/// option should mutate the example's content. Covers both the SwiftUI
/// `pinwheelTweaks` path and the UIKit `Tweakable` → `PinwheelTweak` bridge.
final class TweakableUITests: XCTestCase {
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

    private func openSettings() {
        let settings = app.buttons["pinwheel.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: defaultTimeout), "settings (wrench) button should exist")
        settings.tap()
    }

    /// Navigates the real catalog to `itemName`, switching to `section` via the
    /// picker only when the item isn't already on screen. Because the picker is
    /// opened only when the current section differs from `section`, the section
    /// button is unambiguous (it can't collide with the section-picker button,
    /// which is labelled with the *current* section).
    private func openCatalogItem(_ itemName: String, section: String) {
        // -UITesting resets state, so the catalog always launches to the list —
        // there's no restored item to dismiss first.
        XCTAssertTrue(app.buttons["pinwheel.sectionPicker"].waitForExistence(timeout: defaultTimeout),
                      "section picker should exist")

        let item = app.buttons[itemName]
        if !item.exists {
            app.buttons["pinwheel.sectionPicker"].tap()
            let sectionButton = app.buttons[section]
            XCTAssertTrue(sectionButton.waitForExistence(timeout: defaultTimeout), "\(section) section should be listed")
            sectionButton.tap()
            XCTAssertTrue(item.waitForExistence(timeout: defaultTimeout), "\(itemName) should be listed")
        }
        item.tap()
    }

    // MARK: - SwiftUI pinwheelTweaks

    @MainActor
    func testSwiftUIActionTweakUpdatesContent() {
        launchPreview("tweakable")
        openSettings()

        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: defaultTimeout),
                      "Choosing an action tweak should update the example label")
    }

    @MainActor
    func testSwiftUIToggleTweakUpdatesContent() {
        launchPreview("tweakable")
        openSettings()

        let option3 = app.switches["Option 3, Toggle-backed option"]
        XCTAssertTrue(option3.waitForExistence(timeout: defaultTimeout), "Option 3 toggle should be listed")
        // The row is a single combined element; tapping its center hits the label,
        // so tap the switch control on the trailing edge to actually flip it.
        option3.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()

        // The label updates behind the sheet (no Done button to dismiss anymore).
        XCTAssertTrue(app.staticTexts["Option 3 is on"].waitForExistence(timeout: defaultTimeout),
                      "Toggling a bool tweak should update the example label")
    }

    @MainActor
    func testSwiftUISecondActionTweakStillUpdatesContent() {
        launchPreview("tweakable")

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout))
        option1.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: defaultTimeout))

        openSettings()
        // The row carries a description, so its accessibility label is the
        // combined "title, description".
        let option2 = app.buttons["Option 2, Description 2"]
        XCTAssertTrue(option2.waitForExistence(timeout: defaultTimeout), "Option 2 should still be listed on reopen")
        option2.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 2"].waitForExistence(timeout: defaultTimeout),
                      "A second tweak selection should still update the example label")
    }

    // MARK: - Catalog navigation (the real user path: nested presentation)

    @MainActor
    func testCatalogTweakableActionUpdatesContent() {
        app.launch()

        openCatalogItem("Tweakable", section: "Components")

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: defaultTimeout),
                      "Choosing a tweak from the catalog (nested presentation) should update the label")
    }

    // MARK: - UIKit Tweakable bridge

    @MainActor
    func testCatalogUIKitTweakableActionUpdatesContent() {
        app.launch()

        openCatalogItem("UIKit Tweakable", section: "UIKit")

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1!\n\nYou can drag the button too :D"].waitForExistence(timeout: defaultTimeout),
                      "A UIKit tweak chosen from the catalog should update the hosted view's label")
    }

    @MainActor
    func testUIKitActionTweakUpdatesContent() {
        launchPreview("uikit-tweakable")
        openSettings()

        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "bridged Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1!\n\nYou can drag the button too :D"].waitForExistence(timeout: defaultTimeout),
                      "A bridged UIKit action tweak should update the example label")
    }
}
