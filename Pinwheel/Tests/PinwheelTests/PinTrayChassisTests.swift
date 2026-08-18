import SwiftUI
import XCTest
@testable import Pinwheel

@MainActor
final class PinTrayChassisTests: XCTestCase {
    private func standing(_ tray: PinTray) -> (PinTrayChassis, UIWindow) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        let root = UIViewController()
        window.rootViewController = root
        window.isHidden = false

        let overlay = PinTrayChassis(
            showing: tray,
            nestedIn: UIScreen.main.pinDisplayCornerRadius,
            covering: root.view.bounds
        )
        root.addChild(overlay)
        root.view.addSubview(overlay.view, filling: .all)
        overlay.didMove(toParent: root)
        window.layoutIfNeeded()
        return (overlay, window)
    }

    private func scrollView(in view: UIView) -> UIScrollView? {
        if let found = view as? UIScrollView { return found }
        for subview in view.subviews {
            if let found = scrollView(in: subview) { return found }
        }
        return nil
    }

    func testTheBodyTakesEverythingBelowTheTitleBar() throws {
        let (overlay, window) = standing(
            PinTray("Region") { Color.clear.frame(height: 2_000) }.detent(.filling)
        )
        window.layoutIfNeeded()

        let body = try XCTUnwrap(scrollView(in: overlay.view), "a tray has a scrolling body")
        let inCard = body.convert(body.bounds, to: overlay.view)

        XCTAssertGreaterThan(inCard.minY, 0, "the title bar stands above it")
        XCTAssertEqual(inCard.maxY, overlay.cardBottom, accuracy: 1, "and it runs to the card's own edge")
    }

    func testTheBodyKeepsRoomBelowItsLastRowForWhatFloatsOverIt() throws {
        let (overlay, window) = standing(
            PinTray("Region") { Color.clear.frame(height: 2_000) }
                .detent(.filling)
                .floating { Color.clear.frame(height: 48) }
        )
        window.layoutIfNeeded()

        let body = try XCTUnwrap(scrollView(in: overlay.view), "a tray has a scrolling body")
        XCTAssertGreaterThan(body.contentInset.bottom, 48, "the field's own height, and the gaps around it")
    }

    private func accessories(in view: UIView) -> [PinTrayLeafView] {
        if let slot = view as? PinTrayAccessoryView {
            return slot.subviews.compactMap { $0 as? PinTrayLeafView }
        }
        return view.subviews.flatMap { accessories(in: $0) }
    }

    func testTheCommitButtonHoldsItsSizeAndOpacityThroughAMove() throws {
        let deeper = PinTray("How it works") { Color.clear.frame(height: 300) }.commit("Got It") {}
        let boost = PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {}

        let (overlay, window) = standing(deeper)
        window.layoutIfNeeded()
        overlay.show(boost, isPush: false)
        window.layoutIfNeeded()

        let buttons = accessories(in: overlay.view)
        let inFlight = buttons.map { Set($0.layer.animationKeys() ?? []) }
        XCTAssertEqual(buttons.count, 2, "the button arriving and the one being left")
        XCTAssertEqual(
            inFlight.filter(\.isEmpty).count, 1,
            "the arriving button holds, so nothing about it is in flight: \(inFlight)"
        )
        XCTAssertTrue(
            inFlight.allSatisfy { !$0.contains("transform") },
            "and neither carries the content's zoom: \(inFlight)"
        )
    }

    func testAButtonArrivingWhereSomethingElseStoodFadesInRatherThanAppearing() throws {
        let region = PinTray("Region") { Color.clear.frame(height: 2_000) }
            .detent(.filling)
            .floating { Color.clear.frame(height: 48) }
        let boost = PinTray("Boost") { Color.clear.frame(height: 300) }
            .commit("Boost Post") {}

        let (overlay, window) = standing(region)
        window.layoutIfNeeded()
        overlay.show(boost, isPush: false)
        window.layoutIfNeeded()

        let buttons = accessories(in: overlay.view)
        let inFlight = buttons.map { Set($0.layer.animationKeys() ?? []) }
        XCTAssertEqual(buttons.count, 2, "the button arriving and the field being left")
        XCTAssertEqual(
            inFlight.filter(\.isEmpty).count, 0,
            "neither holds: what arrives is a different thing, so it fades in: \(inFlight)"
        )
    }

    private func dissolvingInFlight(in view: UIView) -> [String] {
        let mine = view is PinTrayLeafView || view is PinTrayBodyView
            ? Set(view.layer.animationKeys() ?? []).sorted()
            : []
        return mine + view.subviews.flatMap { dissolvingInFlight(in: $0) }
    }

    func testATrayTakesVoiceOverOffWhatItCovers() {
        let (overlay, _) = standing(PinTray("Boost") { Color.clear.frame(height: 300) })
        XCTAssertTrue(
            overlay.view.accessibilityViewIsModal,
            "a tray covers the screen behind it, so VoiceOver must not reach past it"
        )
    }

    func testTheEscapeGestureLeavesATrayTheWayTappingOutsideDoes() {
        let (overlay, window) = standing(PinTray("Boost") { Color.clear.frame(height: 300) })
        var gone = false
        overlay.onGone = { gone = true }

        XCTAssertTrue(overlay.accessibilityPerformEscape(), "the tray answers the escape gesture")
        for _ in 0..<150 where !gone {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
        }
        XCTAssertTrue(gone, "and leaves by the same way out as a tap on the backdrop")
    }

    func testAMoveCarriesNoZoomWhenMotionIsReduced() {
        let boost = PinTray("Boost") { Color.clear.frame(height: 300) }.commit("Boost Post") {}
        let deeper = PinTray("How it works") { Color.clear.frame(height: 300) }.commit("Got It") {}

        let (overlay, window) = standing(deeper)
        overlay.motionIsReduced = true
        window.layoutIfNeeded()
        overlay.show(boost, isPush: false)
        window.layoutIfNeeded()

        XCTAssertFalse(
            dissolvingInFlight(in: overlay.view).contains("transform"),
            "the contents cross-dissolve without scaling: \(dissolvingInFlight(in: overlay.view))"
        )
    }

    func testALeavingTrayIsTornDownOnlyOnceItHasTravelled() {
        let (overlay, window) = standing(PinTray("Boost") { Color.clear.frame(height: 300) })
        overlay.dismiss()
        window.layoutIfNeeded()
        XCTAssertNotNil(overlay.view.superview, "still on screen for as long as it is travelling")
    }
}

extension PinTrayChassisTests {
    func testATrayThatFloatsSomethingStandsThatRatherThanACommitButton() {
        let (overlay, _) = standing(PinTray("Boost") { Color.clear.frame(height: 300) })
        let floating = PinTray("Region") { Color.clear }
            .floating { Color.clear.frame(height: 48) }
            .commit("Boost Post") {}
        let committing = PinTray("Boost") { Color.clear }.commit("Boost Post") {}

        XCTAssertFalse(
            overlay.accessory(for: floating).isCommitButton,
            "what a tray floats is its own content, and it takes the bottom"
        )
        XCTAssertTrue(
            overlay.accessory(for: committing).isCommitButton,
            "with nothing floating, the button stands there"
        )
    }
}

extension PinTrayChassisTests {
    func testTheLastTrayExitsTheFlowAndADeeperOneGoesBackAStep() {
        XCTAssertEqual(PinTrayPathSync<Int>.exited([1]), [], "the last tray standing closes the flow")
        XCTAssertEqual(PinTrayPathSync<Int>.exited([1, 2]), [1], "a pushed one goes back a step")
        XCTAssertEqual(PinTrayPathSync<Int>.exited([]), [], "with nothing standing there is nothing to exit")
    }

    func testAPathThatGrowsOrHoldsArrivesLikeAPushAndOneThatShrinksLikeAPop() {
        XCTAssertTrue(PinTrayPathSync<Int>.isPush(to: 2, from: 1), "deeper is a push")
        XCTAssertTrue(
            PinTrayPathSync<Int>.isPush(to: 1, from: 1),
            "and one tray replacing another at the same depth arrives the same way"
        )
        XCTAssertFalse(PinTrayPathSync<Int>.isPush(to: 1, from: 2), "shallower is a pop")
    }

    func testATrayIsNotAssembledUntilItHasJoinedWhatItCovers() {
        let chassis = PinTrayChassis(
            showing: PinTray("Boost") { Color.clear.frame(height: 300) },
            nestedIn: .radiusL,
            covering: CGRect(x: 0, y: 0, width: 420, height: 912)
        )

        _ = chassis.view

        XCTAssertNil(
            scrollView(in: chassis.view),
            "loading the view measures a room it has not got, so nothing is built until it has a parent"
        )
    }
}
