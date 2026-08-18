import SwiftUI
import XCTest
@testable import Pinwheel

@MainActor
final class PinTrayBodyTests: XCTestCase {
    private func rows(_ count: Int) -> AnyView {
        AnyView(
            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { row in
                    Text("Row \(row)").frame(maxWidth: .infinity)
                }
            }
        )
    }

    private func attachedBody(
        showing content: AnyView,
        reporting to: PinTrayBodyCoordinating = PinTrayBodyReports()
    ) -> PinTrayBodyView {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 500))
        window.rootViewController = parent
        window.isHidden = false

        let body = PinTrayBodyView(showing: content, in: parent, reporting: to)
        parent.view.addSubview(body)
        body.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: parent.view.topAnchor),
            body.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
        ])
        window.layoutIfNeeded()
        return body
    }

    func testRowsShownAfterAttachAreLaidOutAsTallAsTheyMeasure() {
        let body = attachedBody(showing: rows(1))
        let single = body.scrollableHeight
        XCTAssertGreaterThan(single, 0, "one row has to have drawn before sixty can be compared to it")

        body.show(rows(60))
        body.superview?.layoutIfNeeded()

        XCTAssertEqual(
            body.scrollableHeight / single,
            60,
            accuracy: 1,
            "rows swapped in after the body is standing still have to be laid out, or none can be touched"
        )
    }

    func testABodyGivenExactlyTheHeightItAskedForHasNothingLeftToScroll() {
        let body = attachedBody(showing: rows(3))
        body.clearance = 24

        let asked = body.contentHeight(fitting: 400)
        body.window?.frame = CGRect(x: 0, y: 0, width: 400, height: asked)
        body.superview?.layoutIfNeeded()

        XCTAssertFalse(
            body.overflows,
            "a card built to the height the body asked for leaves the body nothing to scroll"
        )
    }

    func testTheCardKeepsAPullUntilTheFingerGivesItBack() {
        XCTAssertTrue(
            PinTrayBodyView.cardTakes(30, alreadyPulling: false),
            "a pull past the top belongs to the card"
        )
        XCTAssertTrue(
            PinTrayBodyView.cardTakes(-20, alreadyPulling: true),
            "and it keeps the rest of that gesture, so the finger can bring the card back"
        )
        XCTAssertFalse(
            PinTrayBodyView.cardTakes(-20, alreadyPulling: false),
            "a drag up that never pulled is the list's"
        )
    }

    func testOnlyABodyOutgrowingItsRoomScrolls() {
        XCTAssertFalse(
            attachedBody(showing: rows(2)).scrolls,
            "rows that already fit have nowhere to go, so the body must not scroll at all"
        )
        XCTAssertTrue(
            attachedBody(showing: rows(60)).scrolls,
            "rows that outgrow the body still scroll"
        )
    }

    func testABodyReportsEachSliceOfAPullAndKeepsNoRunningTotal() {
        let reports = PinTrayBodyReports()
        let body = attachedBody(showing: rows(60), reporting: reports)

        body.wasPulled(pastTheTop: 10)
        body.wasPulled(pastTheTop: 10)
        body.wasPulled(pastTheTop: 10)

        XCTAssertEqual(reports.pulls, [10, 10, 10], "each frame's own slice, added up by whoever holds it")
    }
}
