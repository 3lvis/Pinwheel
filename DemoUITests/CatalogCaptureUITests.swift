import XCTest
import DemoCatalog

// KEEP: app-layer wiring a unit can't reach. Opening a catalog item fires the
// auto-push Figma capture (reflect → DisplayList) against the live view, and the
// reflector lives in the Demo app target with no unit-test target to import it. A
// demo built from a ForEach trapped the reflector and crashed the app on open;
// this drives the real catalog-open path that runs the capture.
final class CatalogCaptureUITests: XCTestCase {
    private var app: XCUIApplication!

    // Only bounds how long a failing test waits — waitForExistence returns as soon
    // as the element appears. Generous because opening runs the capture first.
    private let defaultTimeout: TimeInterval = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOpeningTheNumbersDemoRunsCaptureWithoutCrashing() {
        app.launch()
        openCatalogItem(.numbers, .swiftUI, in: .tokens)
        // The demo renders — so the catalog opened it and the auto-push capture ran
        // without the reflector trapping and taking the app down.
        XCTAssertTrue(app.staticTexts["spacingXXS 2"].waitForExistence(timeout: defaultTimeout),
                      "Numbers demo should render after the catalog opens it and runs capture")
    }

    // The button demo folds the layout stressors into one screen — side-by-side rows, a
    // space-between Spacer, and a filled/clipped card — so it's the richest capture fixture.
    // Opening it guards the reflector/DisplayList against regressions on all of those as the
    // shared capture engine evolves.
    @MainActor
    func testOpeningTheButtonDemoRunsCaptureWithoutCrashing() {
        app.launch()
        openCatalogItem(.button, .swiftUI, in: .components)
        // The card renders — so the catalog opened the demo and the auto-push capture ran over
        // its HStacks, Spacer, and clipped card without the reflector trapping.
        XCTAssertTrue(app.staticTexts["Payment method"].waitForExistence(timeout: defaultTimeout),
                      "Button demo should render after the catalog opens it and runs capture")
    }

    // Matches items by stable id, not title, and scrolls the lazy list into range.
    @MainActor
    private func openCatalogItem(_ component: Catalog, _ tag: PinTag, in section: CatalogSection) {
        XCTAssertTrue(app.buttons["pinwheel.sectionPicker"].waitForExistence(timeout: defaultTimeout),
                      "section picker should exist")

        let itemID = component.id(tag)
        let item = app.buttons[itemID]
        if !item.exists {
            app.buttons["pinwheel.sectionPicker"].tap()
            let sectionButton = app.buttons[section.rawValue]
            XCTAssertTrue(sectionButton.waitForExistence(timeout: defaultTimeout), "\(section.rawValue) section should be listed")
            sectionButton.tap()
            var swipes = 0
            while !item.waitForExistence(timeout: 1) && swipes < 8 {
                app.swipeUp()
                swipes += 1
            }
            XCTAssertTrue(item.exists, "\(itemID) should be listed")
        }
        if item.isHittable {
            item.tap()
        } else {
            item.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
