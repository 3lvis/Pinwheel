import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class UIKitStateViewBridgeTests: XCTestCase {
    private final class SpyDelegate: UIPinStateViewDelegate {
        var actionCount = 0

        func stateViewDidSelectAction(_ stateView: UIPinStateView) {
            actionCount += 1
        }
    }

    private struct Fixture: UIViewRepresentable {
        let stateView: UIPinStateView

        func makeUIView(context: Context) -> UIPinStateView { stateView }
        func updateUIView(_ uiView: UIPinStateView, context: Context) {}
    }

    func testTheShellBridgesItsHostedActionToTheDelegate() throws {
        let delegate = SpyDelegate()
        let stateView = UIPinStateView()
        stateView.delegate = delegate
        stateView.state = .failed(title: "Oops!", subtitle: "Something went wrong.", actionTitle: "Retry")

        let window = HostedView.window(showing: Fixture(stateView: stateView))
        addTeardownBlock {
            window.isHidden = true
            window.rootViewController = nil
        }

        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Retry", in: window),
            "the hosted SwiftUI action should be reachable through the UIKit shell"
        )
        XCTAssertEqual(
            delegate.actionCount,
            1,
            "the shell hosts PinStateView, so its action has to cross the bridge to the delegate"
        )
    }
}
