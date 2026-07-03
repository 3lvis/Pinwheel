import XCTest
import DemoCatalog

/// App-layer wiring for tweaks that a unit can't reach: the settings sheet →
/// content re-render, nested catalog presentation, and UIKit hosting. The tweak
/// model and the `Tweakable` → `PinwheelTweak` bridge logic are unit-tested in
/// `PinwheelTweakTests`; these guard only the glue. Grow unit coverage by default
/// — a new UI test here is the exception, justified by an app-layer fact.
final class TweakableUITests: XCTestCase {
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

    // Matches items by stable id, not title: with world (SwiftUI/UIKit) now a
    // tag, two rows in a section can share a title (e.g. both "Tweakable").
    private func openCatalogItem(_ component: Catalog, _ tag: PinTag, in section: CatalogSection) {
        // -UITesting resets state, so the catalog always launches to the list —
        // no restored item to dismiss first.
        XCTAssertTrue(app.buttons["pinwheel.sectionPicker"].waitForExistence(timeout: defaultTimeout),
                      "section picker should exist")

        let itemID = component.id(tag)
        let item = app.buttons[itemID]
        if !item.exists {
            app.buttons["pinwheel.sectionPicker"].tap()
            let sectionButton = app.buttons[section.rawValue]
            XCTAssertTrue(sectionButton.waitForExistence(timeout: defaultTimeout), "\(section.rawValue) section should be listed")
            sectionButton.tap()
            // The catalog list is lazy — a row far down isn't in the accessibility
            // tree until scrolled into range (a smaller/slower CI sim shows fewer rows).
            var swipes = 0
            while !item.waitForExistence(timeout: 1) && swipes < 8 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(item.exists, "\(itemID) should be listed")
        }
        item.tap()
    }

    // KEEP: app-layer wiring — tweak preferences survive the settings sheet
    // closing and reopening across a playground re-render. (Tweak invocation
    // itself is unit-tested in PinwheelTweakTests.)
    @MainActor
    func testSwiftUISecondActionTweakStillUpdatesContent() {
        launchPreview(.tweakable, .swiftUI)

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout))
        option1.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: defaultTimeout))

        openSettings()
        // A described row's accessibility label is the combined "title, description".
        let option2 = app.buttons["Option 2, Description 2"]
        XCTAssertTrue(option2.waitForExistence(timeout: defaultTimeout), "Option 2 should still be listed on reopen")
        option2.tap()
        XCTAssertTrue(app.staticTexts["Chosen Option 2"].waitForExistence(timeout: defaultTimeout),
                      "A second tweak selection should still update the example label")
    }

    // KEEP: app-layer wiring — the real user path (catalog list → fullScreenCover
    // → playground → sheet) that a unit can't drive.
    @MainActor
    func testCatalogTweakableActionUpdatesContent() {
        app.launch()

        openCatalogItem(.tweakable, .swiftUI, in: .components)

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1"].waitForExistence(timeout: defaultTimeout),
                      "Choosing a tweak from the catalog (nested presentation) should update the label")
    }

    // KEEP: app-layer wiring — the UIKit Tweakable bridge end-to-end plus hosting
    // driving the on-screen instance (the mapping itself is in PinwheelTweakTests).
    @MainActor
    func testCatalogUIKitTweakableActionUpdatesContent() {
        app.launch()

        openCatalogItem(.tweakable, .uiKit, in: .components)

        openSettings()
        let option1 = app.buttons["Option 1"]
        XCTAssertTrue(option1.waitForExistence(timeout: defaultTimeout), "Option 1 should be listed")
        option1.tap()

        XCTAssertTrue(app.staticTexts["Chosen Option 1!\n\nYou can drag the button too :D"].waitForExistence(timeout: defaultTimeout),
                      "A UIKit tweak chosen from the catalog should update the hosted view's label")
    }

    // KEEP: app-layer wiring — a SwiftUI layout-engine crash no unit can reproduce.
    @MainActor
    func testSelectingSimulatedDeviceDoesNotCrash() {
        launchPreview(.tweakable, .swiftUI)
        openSettings()

        let deviceButton = app.buttons["iphone.gen3"]
        XCTAssertTrue(deviceButton.waitForExistence(timeout: defaultTimeout), "device nav button should exist")
        deviceButton.tap()

        let device = app.buttons["iPhone XS/11 Pro"]
        XCTAssertTrue(device.waitForExistence(timeout: defaultTimeout), "iPhone XS/11 Pro should be listed")
        device.tap()

        // Selecting a simulated device used to crash the app (an implicitly
        // animated resize overflowed SwiftUI's layout engine). Re-querying another
        // row proves the app survived, since a crashed/hung app fails this query.
        XCTAssertTrue(app.buttons["iPhone SE (2nd & 3rd generation)"].waitForExistence(timeout: defaultTimeout),
                      "device list should stay responsive after selecting a device")
    }
}
