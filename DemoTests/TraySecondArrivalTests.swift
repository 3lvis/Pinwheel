import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
final class TraySecondArrivalTests: XCTestCase {
    private func settle(_ window: UIWindow, until reached: () -> Bool) {
        for _ in 0..<250 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
            if reached() { return }
        }
    }

    private func openATray(in root: UIViewController, of window: UIWindow) -> PinTrayChassis {
        let chassis = PinTrayChassis(
            showing: PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {},
            nestedIn: UIScreen.main.pinDisplayCornerRadius,
            covering: root.view.bounds
        )
        root.addChild(chassis)
        root.view.addSubview(chassis.view, filling: .all)
        chassis.didMove(toParent: root)
        settle(window) { chassis.cardHeight > 0 }
        return chassis
    }

    func testASecondTrayRestsOnTheFloorJustAsTheFirstDid() throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.first as? UIWindowScene,
            "the host app has no window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()

        let first = openATray(in: root, of: window)
        let restingPlace = first.cardBottom
        XCTAssertEqual(
            restingPlace, first.view.bounds.maxY - trayBottomMargin, accuracy: 1,
            "the first tray rests a bottom margin above the floor"
        )

        first.dismiss()
        settle(window) { first.parent == nil }

        let second = openATray(in: root, of: window)
        XCTAssertEqual(
            second.cardBottom, restingPlace, accuracy: 1,
            "a second tray stands where the first did, rather than floating up with nothing pinning it: "
                + "\(second.cardBottom) against \(restingPlace)"
        )
    }
}
