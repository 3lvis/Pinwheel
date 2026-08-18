import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
final class TrayKeyboardCornerTests: XCTestCase {
    private func field(in view: UIView) -> UITextField? {
        if let field = view as? UITextField { return field }
        for subview in view.subviews {
            if let found = field(in: subview) { return found }
        }
        return nil
    }

    private func settle(_ window: UIWindow, until reached: () -> Bool) {
        for _ in 0..<200 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
            if reached() { return }
        }
    }

    func testATrayRidingTheKeyboardWearsItsOwnCornersRatherThanTheDisplays() throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.first as? UIWindowScene,
            "the host app has no window scene"
        )
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()

        let boost = PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {}
        let region = PinTray("Region") { Editable().frame(height: 44) }.detent(.filling)

        let overlay = PinTrayChassis(
            showing: boost,
            nestedIn: UIScreen.main.pinDisplayCornerRadius,
            covering: root.view.bounds
        )
        root.addChild(overlay)
        root.view.addSubview(overlay.view, filling: .all)
        overlay.didMove(toParent: root)
        window.layoutIfNeeded()
        settle(window) { overlay.bottomCornerRadius > 0 }

        XCTAssertEqual(
            overlay.bottomCornerRadius, UIScreen.main.pinDisplayCornerRadius, accuracy: 1,
            "resting on the floor, it is nested in the display's own corner"
        )

        overlay.show(region, isPush: true)
        window.layoutIfNeeded()
        let editable = try XCTUnwrap(field(in: overlay.view), "the region tray stands something to type in")
        let took = editable.becomeFirstResponder()
        XCTAssertTrue(took, "the field refused first responder")
        XCTAssertTrue(editable.isFirstResponder, "the field is not editing")
        XCTAssertNotNil(editable.window, "the field is not in a window")

        settle(window) { overlay.cardBottom < window.bounds.height - 100 }
        XCTAssertLessThan(
            overlay.cardBottom, window.bounds.height - 100,
            "the keyboard never lifted the card, so this proves nothing"
        )

        XCTAssertEqual(
            overlay.bottomCornerRadius, trayTopRadius, accuracy: 1,
            "lifted off the floor, it is nested in nothing and wears its own corner"
        )
    }
}

private struct Editable: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField { UITextField() }
    func updateUIView(_ view: UITextField, context: Context) {}
}
