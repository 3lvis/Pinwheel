import XCTest
import SwiftUI
import UIKit
@testable import Demo
@testable import Pinwheel

@MainActor
final class LiveCaptureHostSizingTests: XCTestCase {
    private struct TallScreen: SwiftUI.View {
        var body: some SwiftUI.View {
            ScrollView {
                VStack(spacing: .spacing3) {
                    ForEach(0..<40, id: \.self) { index in
                        PinButton("Row \(index)") {}
                    }
                }
            }
        }
    }

    private func hostedHeight(of view: some SwiftUI.View) throws -> CGFloat {
        let entry = FigmaCatalogEntry(
            id: "tall",
            title: "Tall",
            section: "Screens",
            tags: [],
            item: PinwheelItem("Tall") { view }
        )
        let window = HostedView.window(showing: LiveCaptureHost(entry: entry))
        addTeardownBlock {
            window.isHidden = true
            window.rootViewController = nil
        }
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        window.layoutIfNeeded()

        func innermost(_ controller: UIViewController) -> UIViewController {
            controller.children.last.map(innermost) ?? controller
        }
        let root = try XCTUnwrap(window.rootViewController)
        let host = innermost(root)
        XCTAssertNotIdentical(host, root, "the capture host should have built a hosting controller for the entry")
        return host.view.bounds.height
    }

    func testTheCaptureHostGrowsPastTheScreenSoEveryRowRenders() throws {
        let screenHeight = UIScreen.main.bounds.height
        let height = try hostedHeight(of: TallScreen())

        XCTAssertGreaterThan(
            height,
            screenHeight,
            "a screen taller than the device has to render in full — clamped to the window its below-the-fold rows never enter the DisplayList, and the whole capture falls back to a flat image"
        )
    }

    func testAShortScreenStillStandsAtScreenHeightSoItsControlsPaintOnWindow() throws {
        let screenHeight = UIScreen.main.bounds.height
        let height = try hostedHeight(of: PinLabel("Short"))

        XCTAssertEqual(
            height,
            screenHeight,
            accuracy: 1.0,
            "short content must not shrink the host below the screen, or a UIKit control has no on-window area to paint into"
        )
    }
}
