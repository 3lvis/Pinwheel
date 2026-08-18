import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
final class TrayOnlyOneTests: XCTestCase {
    private func spin(_ window: UIWindow, for seconds: TimeInterval) {
        let until = Date().addingTimeInterval(seconds)
        while Date() < until {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
        }
    }

    func testATrayRescuedOnItsWayOutIsTheOneThatOpensNextTime() throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.first as? UIWindowScene,
            "the host app has no window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()

        let sync = PinTrayPathSync<Int>()
        let tray = { PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {} }

        sync.sync(path: [0], from: presenter) { _ in tray() }
        spin(window, for: 0.6)

        let leaving = try XCTUnwrap(
            presenter.children.compactMap { $0 as? PinTrayChassis }.first,
            "a tray is standing"
        )

        sync.sync(path: [], from: presenter) { _ in tray() }
        spin(window, for: 0.05)

        leaving.cardWasTouched()
        spin(window, for: 0.5)

        sync.sync(path: [0], from: presenter) { _ in tray() }
        spin(window, for: 0.6)

        let trays = presenter.children.compactMap { $0 as? PinTrayChassis }
        XCTAssertEqual(
            trays.count, 1,
            "one tray stands at a time — reopening while the last is still leaving must reuse it, not stack: \(trays.count)"
        )
    }

    func testARescuedTrayNeverTellsTheAppItWent() throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.first as? UIWindowScene,
            "the host app has no window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()

        var cleared = 0
        let sync = PinTrayPathSync<Int>()
        sync.dismissAll = { cleared += 1 }
        sync.sync(path: [0], from: presenter) { _ in
            PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {}
        }
        spin(window, for: 0.6)

        let tray = try XCTUnwrap(
            presenter.children.compactMap { $0 as? PinTrayChassis }.first,
            "a tray is standing"
        )

        tray.cardWasDragged(to: 400)
        tray.cardWasReleased(velocity: 2_000)
        spin(window, for: 0.05)
        tray.cardWasTouched()
        spin(window, for: 0.5)

        XCTAssertEqual(
            cleared, 0,
            "a tray caught and stood back up never left, so the path it was opened from still holds it"
        )
    }
}

