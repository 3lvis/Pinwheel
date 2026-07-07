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

    // KEEP: guards the live-sweep host sizing, which no unit can reach. `LiveCaptureHost` sizes the
    // on-screen host to `max(screen, content)` so a screen taller than the device (the button showcase)
    // renders every row into the DisplayList; clamped to the window, the below-the-fold rows drop, the
    // reflected count outnumbers the rendered leaves, and the whole screen falls to the containment
    // fallback — losing every pill. That sizing lives in the Demo target and only manifests through the
    // real `-PinwheelCapture` render, so a library unit test (CaptureFidelityTests) can pin the
    // height-sensitivity mechanism but not this. Drives the actual sweep and asserts the captured screen
    // kept its content.
    @MainActor
    func testSweepCapturingTheTallButtonScreenKeepsEveryPill() {
        app.launchArguments += ["-PinwheelCapture", Catalog.button.id(.swiftUI)]
        app.launch()
        let summary = app.staticTexts["capture.summary"]
        // Generous only as a failure ceiling: the sweep renders the screen and runs the capture first.
        XCTAssertTrue(summary.waitForExistence(timeout: 20), "the sweep capture should publish its summary")
        let label = summary.label
        XCTAssertTrue(label.contains("tag=screen"),
                      "the tall button screen must capture via the reflection path, not the containment fallback — got \(label)")
        let pills = label.components(separatedBy: "pills=").last.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? 0
        XCTAssertGreaterThanOrEqual(pills, 10,
                                    "every button pill must be captured (the demo has ~17); a window-clamped host drops all but one — got \(label)")
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
