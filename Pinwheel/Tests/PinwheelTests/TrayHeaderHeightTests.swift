import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
final class TrayHeaderHeightTests: XCTestCase {
    func testTheTitleBarRunsFromTheTopEdgeToTheHairlineAtTheControlFloorPlusASpacingEachSide() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false
        addTeardownBlock {
            window.isHidden = true
            window.rootViewController = nil
        }

        let tray = PinTrayChassis(
            showing: PinTray("Section") {
                PinTraySection {
                    PinTrayChoice("Tokens", isChosen: true) {}
                    PinTrayChoice("Components", isChosen: false) {}
                }
            },
            nestedIn: UIScreen.main.pinDisplayCornerRadius,
            covering: root.view.bounds
        )
        root.addChild(tray)
        root.view.addSubview(tray.view, filling: .all)
        tray.didMove(toParent: root)
        for _ in 0..<50 where tray.cardHeight <= 0 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
        }

        let contents = try XCTUnwrap(first(PinTrayContentsView.self, in: tray.view), "a tray holds its contents")
        let hairline = try XCTUnwrap(rule(in: contents), "a tray rules off its title bar")

        XCTAssertEqual(
            hairline.convert(hairline.bounds, to: contents).minY,
            .minimumControlHeight + .spacing1 * 2,
            accuracy: 0.5,
            "the title bar is the 48pt control floor with one spacing-1 above and below"
        )
        XCTAssertEqual(hairline.bounds.height, 1, accuracy: 0.01, "and it rules off with a single point")
    }

    private func first<Kind: UIView>(_ kind: Kind.Type, in view: UIView) -> Kind? {
        if let found = view as? Kind { return found }
        for subview in view.subviews {
            if let found = first(kind, in: subview) { return found }
        }
        return nil
    }

    private func rule(in view: UIView) -> UIView? {
        view.subviews
            .filter { $0.subviews.isEmpty && $0.bounds.height <= 1.5 && $0.bounds.width > 200 }
            .min { $0.frame.minY < $1.frame.minY }
    }
}
