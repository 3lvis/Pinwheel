import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
final class TrayDimTape: XCTestCase {
    private func settle(_ window: UIWindow, until reached: () -> Bool) {
        for _ in 0..<200 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
            if reached() { return }
        }
    }

    private func backdrop(in view: UIView) -> UIView? {
        for subview in view.subviews {
            if subview.backgroundColor?.cgColor.alpha ?? 0 > 0, subview.subviews.isEmpty { return subview }
            if let found = backdrop(in: subview) { return found }
        }
        return nil
    }

    func testTheBackdropTracksTheCardThroughADrag() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.screen.bounds
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()

        let sync = PinTrayPathSync<Int>()
        sync.sync(path: [0], from: presenter) { _ in
            PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {}
        }
        settle(window) { (presenter.children.compactMap { $0 as? PinTrayChassis }.first?.cardHeight ?? 0) > 0 }

        let tray = try XCTUnwrap(presenter.children.compactMap { $0 as? PinTrayChassis }.first)
        let dim = try XCTUnwrap(backdrop(in: tray.view), "the tray dims what it covers")

        var tape: [(CGFloat, CGFloat)] = []
        for pulled in stride(from: CGFloat(0), through: 400, by: 50) {
            tray.cardWasDragged(to: pulled)
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
            tape.append((tray.cardBottom, dim.alpha))
        }

        print("=== TAPE  cardBottom → backdrop ===")
        for (bottom, alpha) in tape { print(String(format: "  %7.1f  %.2f", bottom, alpha)) }

        let alphas = tape.map(\.1)
        XCTAssertEqual(alphas.first ?? 0, 1, accuracy: 0.01, "full while it stands")
        XCTAssertEqual(
            alphas, alphas.sorted(by: >), accuracy: 0.001,
            "the backdrop only ever clears as the card goes down: \(alphas)"
        )
        XCTAssertLessThan(alphas.last!, 0.75, "and it has visibly cleared by the end of the drag: \(alphas.last!)")
    }
}

private func XCTAssertEqual(
    _ one: [CGFloat], _ two: [CGFloat], accuracy: CGFloat, _ message: String
) {
    for (a, b) in zip(one, two) where abs(a - b) > accuracy {
        XCTFail(message)
        return
    }
}
