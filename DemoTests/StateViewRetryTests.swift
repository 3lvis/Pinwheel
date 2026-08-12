import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class StateViewRetryTests: XCTestCase {
    private struct Fixture: SwiftUI.View {
        @SwiftUI.State private var state: PinState = .failed(
            title: "Oops!",
            subtitle: "Something went wrong.",
            actionTitle: "Retry"
        )

        var body: some SwiftUI.View {
            PinStateView(state) {
                state = .loading(title: "Loading...", subtitle: "Hold on.")
            }
        }
    }

    func testActivatingTheFailedStateActionSwitchesTheViewToLoading() throws {
        let window = HostedView.window(showing: Fixture())
        addTeardownBlock {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(
            HostedView.accessibilityLabels(in: window).contains("Oops!"),
            "the failed state should render its title"
        )
        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Retry", in: window),
            "the failed state's action should be reachable and activatable"
        )

        XCTAssertTrue(
            HostedView.accessibilityLabels(in: window).contains("Loading..."),
            "activating Retry should fire the action and switch the state view to loading"
        )
    }
}
