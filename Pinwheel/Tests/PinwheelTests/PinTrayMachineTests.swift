import XCTest
@testable import Pinwheel

@MainActor
final class PinTrayMachineTests: XCTestCase {
    private let screen = PinTrayGeometry.Room(
        containerHeight: 912,
        safeAreaTop: 62,
        safeAreaBottom: 34,
        displayCornerRadius: 62
    )

    private func machine(standing height: CGFloat = 641, edits: Bool = false) -> PinTrayMachine {
        var machine = PinTrayMachine(room: screen)
        _ = machine.handle(.presented(contentHeight: height))
        if edits {
            _ = machine.handle(.moved(contentHeight: height, edits: true, isPush: true))
            _ = machine.handle(.keyboardMeasured(311))
        }
        return machine
    }

    func testATrayArrivesFromBelowItsOwnBottomEdge() {
        var machine = PinTrayMachine(room: screen)
        let reaction = machine.handle(.presented(contentHeight: 641))
        let from = try! XCTUnwrap(reaction.from)
        XCTAssertGreaterThan(from.translation, 0, "it starts below its place")
        XCTAssertEqual(reaction.to.translation, 0, "and travels to it")
        XCTAssertEqual(reaction.timeline, .spring(bounce: trayResizeBounce, initialVelocity: 0))
    }

    func testATrayAboutToEditHoldsStillUntilTheKeyboardMoves() {
        var machine = machine()
        let standing = machine.geometry

        let push = machine.handle(.moved(contentHeight: 456, edits: true, isPush: true))
        XCTAssertTrue(machine.isAwaitingKeyboard)
        XCTAssertEqual(push.timeline, .carriedByKeyboard, "the keyboard owns this move, so we start nothing")

        let opening = machine.handle(.keyboardMeasured(311))
        XCTAssertEqual(opening.timeline, .carriedByKeyboard)
        let height = screen.containerHeight
        let top = { (g: PinTrayGeometry) in height - g.bottomInset - g.height }
        XCTAssertLessThan(top(opening.to), top(standing), "the top only ever travels up")
    }

    func testTheTopNeverReversesOnTheWayToTheKeyboard() {
        var machine = machine()
        let height = screen.containerHeight
        var tops = [height - machine.geometry.bottomInset - machine.geometry.height]
        for event in [PinTrayMachine.Event.moved(contentHeight: 456, edits: true, isPush: true),
                      .keyboardMeasured(311),
                      .keyboardMeasured(311)] {
            let reaction = machine.handle(event)
            tops.append(height - reaction.to.bottomInset - reaction.to.height)
        }
        XCTAssertEqual(tops, tops.sorted(by: >), "the top descends at no point: \(tops)")
    }

    func testLeavingAnEditingTrayDismissesTheKeyboardDeliberately() {
        var machine = machine(edits: true)
        let pop = machine.handle(.moved(contentHeight: 641, edits: false, isPush: false))
        XCTAssertEqual(pop.effects, [.dismissKeyboard])
    }

    func testComingBackFromAnEditingTrayReturnsToTheHeightItLeftFrom() {
        var machine = machine()
        let standing = machine.geometry.height

        _ = machine.handle(.moved(contentHeight: 456, edits: true, isPush: true))
        _ = machine.handle(.keyboardMeasured(311))
        _ = machine.handle(.keyboardMeasured(311))

        let keyboardAskedToGoButStillThere = true
        let pop = machine.handle(
            .moved(contentHeight: standing, edits: keyboardAskedToGoButStillThere, isPush: false)
        )
        XCTAssertEqual(pop.to.height, standing, "it comes back to the height it left from")
    }

    func testCommandingTheKeyboardAwayCountsAsTheKeyboardLeaving() {
        var machine = machine(edits: true)
        let pop = machine.handle(.moved(contentHeight: 641, edits: true, isPush: false))

        XCTAssertEqual(pop.effects, [.dismissKeyboard])
        XCTAssertEqual(machine.keyboard.height, 0, "it does not go on believing the keyboard is up")
        XCTAssertEqual(
            machine.handle(.keyboardMeasured(0)).to,
            pop.to,
            "the keyboard reporting what it was told changes nothing, so arrival order cannot matter"
        )
    }

    func testAFillingTrayKeepsItsTopWhereverTheKeyboardIs() {
        var machine = PinTrayMachine(room: screen)
        _ = machine.handle(.fillsReported(true))
        _ = machine.handle(.presented(contentHeight: 0))
        _ = machine.handle(.moved(contentHeight: 0, edits: true, isPush: true))

        let height = screen.containerHeight
        let top = { (geometry: PinTrayGeometry) in height - geometry.bottomInset - geometry.height }
        var tops: [CGFloat] = []
        var bottoms: [CGFloat] = []
        for measured in [311, 311, 240, 160, 80, 0, 0, 311] as [CGFloat] {
            let reaction = machine.handle(.keyboardMeasured(measured))
            tops.append(top(reaction.to))
            bottoms.append(reaction.to.bottomInset)
        }
        XCTAssertEqual(Set(tops).count, 1, "the top never moves: \(tops)")
        XCTAssertEqual(bottoms.min(), trayBottomMargin, "and the bottom stops at the floor: \(bottoms)")
    }

    func testATrayLearningItFillsDrawsNothingUntilTheNextEventCarriesIt() {
        var machine = machine()
        let standing = machine.geometry
        _ = machine.handle(.moveBegan(isPush: true))

        let reported = machine.handle(.fillsReported(true))
        XCTAssertEqual(reported.to, standing, "learning it fills moves nothing on its own")
        XCTAssertEqual(reported.timeline, .carriedByKeyboard, "and starts nothing of ours")

        let moved = machine.handle(.moved(contentHeight: 200, edits: false, isPush: true))
        XCTAssertGreaterThan(moved.to.height, 200, "the next event stands it in the room it has")
    }

    func testATrayLearningItFillsAfterItHasArrivedStandsInTheRoomAtOnce() {
        var machine = machine()
        _ = machine.handle(.moveBegan(isPush: true))
        _ = machine.handle(.moved(contentHeight: 200, edits: false, isPush: true))

        let reaction = machine.handle(.fillsReported(true))
        XCTAssertGreaterThan(reaction.to.height, 200, "a tray that has arrived stands up when it learns")
    }

    func testATrayFillsTheRoomWhicheverOrderItsFlagAndItsMoveArriveIn() {
        for flagFirst in [true, false] {
            var machine = machine()
            _ = machine.handle(.moveBegan(isPush: true))
            if flagFirst { _ = machine.handle(.fillsReported(true)) }
            let moved = machine.handle(.moved(contentHeight: 200, edits: false, isPush: true))
            let standing = flagFirst ? moved : machine.handle(.fillsReported(true))

            XCTAssertGreaterThan(
                standing.to.height,
                500,
                "flag \(flagFirst ? "before" : "after") the move: it stands in the room either way"
            )
        }
    }

    func testATrayThatWillRaiseNoKeyboardDoesNotWaitForOne() {
        var machine = machine()
        _ = machine.handle(.moveBegan(isPush: true))

        let pushed = machine.handle(.moved(contentHeight: 245, edits: false, isPush: true))
        XCTAssertEqual(machine.phase, .standing, "nothing is coming, so nothing is waited for")
        XCTAssertEqual(pushed.to.height, 245, "it stands at what it holds")
    }

    func testAFillingTrayNeverWaitsBecauseItsTopCannotMove() {
        var machine = machine()
        _ = machine.handle(.moveBegan(isPush: true))
        _ = machine.handle(.fillsReported(true))

        let pushed = machine.handle(.moved(contentHeight: 245, edits: true, isPush: true))
        XCTAssertEqual(machine.phase, .standing, "it stands at once")

        let height = screen.containerHeight
        let top = { (geometry: PinTrayGeometry) in height - geometry.bottomInset - geometry.height }
        XCTAssertEqual(
            top(machine.handle(.keyboardMeasured(311)).to),
            top(pushed.to),
            accuracy: 0.5,
            "and the keyboard arriving moves only its bottom"
        )
    }

    func testLeavingATrayThatWasNotEditingAsksNothingOfTheKeyboard() {
        var machine = machine()
        let pop = machine.handle(.moved(contentHeight: 456, edits: false, isPush: false))
        XCTAssertEqual(pop.effects, [])
    }

    func testAMovingKeyboardAlwaysOwnsTheTimeline() {
        var machine = machine(edits: true)
        XCTAssertEqual(machine.handle(.keyboardMeasured(0)).timeline, .carriedByKeyboard)
        XCTAssertEqual(machine.handle(.keyboardMeasured(311)).timeline, .carriedByKeyboard)
    }

    func testASettledKeyboardOwnsNothing() {
        var machine = machine(edits: true)
        _ = machine.handle(.keyboardMeasured(311))
        XCTAssertEqual(machine.handle(.contentResized(300)).timeline, .spring(bounce: 0, initialVelocity: 0))
    }

    func testAReactionThatChangesNothingStartsNothing() {
        var machine = machine(edits: true)
        let settled = machine.handle(.keyboardMeasured(311))
        XCTAssertEqual(settled.to, machine.geometry, "nothing about the tray changed")
        XCTAssertEqual(
            settled.timeline,
            .carriedByKeyboard,
            "so nothing of ours starts; a spring here fights whatever is still moving"
        )
    }

    func testContentSettlingCarriesNoBounce() {
        var machine = machine()
        XCTAssertEqual(machine.handle(.contentResized(300)).timeline, .spring(bounce: 0, initialVelocity: 0))
    }

    func testADragTracksTheFingerDownAndResistsItUp() {
        var machine = machine()
        XCTAssertEqual(machine.handle(.dragged(120)).timeline, .immediate)
        XCTAssertEqual(machine.geometry.translation, 120)

        _ = machine.handle(.dragged(-80))
        let lifted = machine.geometry.translation
        XCTAssertLessThan(lifted, 0, "a drag upward lifts it")
        XCTAssertGreaterThan(lifted, -80, "by less than the finger came")
    }

    func testAThrowIsJudgedByWhereItWouldLandNotByHowFastItLeft() {
        var machine = machine()
        _ = machine.handle(.dragged(10))
        let thrown = machine.handle(.released(velocity: 500))
        XCTAssertTrue(
            thrown.dismisses,
            "ten points let go at five hundred a second coasts far past four hundred, whatever a speed"
                + " cutoff would have said about the five hundred"
        )
    }

    func testAReleaseTooSlowToBeAThrowIsJudgedOnHowFarItCame() {
        var machine = machine()
        _ = machine.handle(.dragged(10))
        let nudged = machine.handle(.released(velocity: 100))
        XCTAssertFalse(nudged.dismisses, "a hand coming to rest is not a throw, so ten points is ten points")
    }

    func testAPullUpSpringsBackRatherThanDismissing() {
        var machine = machine()
        _ = machine.handle(.dragged(-200))
        let released = machine.handle(.released(velocity: -900))
        XCTAssertFalse(released.dismisses, "a tray pulled away from the exit does not take it")
        XCTAssertEqual(released.to.translation, 0, "it comes back to where it stood")
    }

    func testAReleasedDragSpringsBackUnlessItWentFarEnough() {
        var machine = machine()
        _ = machine.handle(.dragged(40))
        let held = machine.handle(.released(velocity: 0))
        XCTAssertFalse(held.dismisses)

        _ = machine.handle(.dragged(machine.geometry.height))
        let let_go = machine.handle(.released(velocity: 0))
        XCTAssertTrue(let_go.dismisses, "carried its own height down, the way out is the nearer place")
        XCTAssertGreaterThan(let_go.to.translation, 0, "it leaves the way it arrived")
    }

    func testATrayCaughtOnItsWayOutStopsLeaving() {
        var machine = machine()
        _ = machine.handle(.dragged(machine.geometry.height))
        XCTAssertTrue(machine.handle(.released(velocity: 0)).dismisses)
        XCTAssertEqual(machine.phase, .leaving)

        _ = machine.handle(.caught(at: 200))
        XCTAssertEqual(machine.phase, .standing, "a hand on a leaving tray is a hand bringing it back")
        XCTAssertEqual(machine.geometry.translation, 200, "and it carries on from where it had got to")
    }

    func testAFlickDismissesEvenFromCloseBy() {
        var machine = machine()
        _ = machine.handle(.dragged(20))
        XCTAssertTrue(machine.handle(.released(velocity: 2_000)).dismisses)
    }

    func testAMoveResolvingAfterDismissalDoesNotPutTheTrayBack() {
        var machine = machine()
        let leaving = machine.handle(.dismissed)
        XCTAssertGreaterThan(leaving.to.translation, 0)

        let late = machine.handle(.moved(contentHeight: 641, edits: false, isPush: true))
        XCTAssertGreaterThan(
            late.to.translation, 0,
            "a move that resolves on its way out cannot stand the tray back up"
        )
    }

    func testATrayThatIsLeavingIsNeverPutBack() {
        var machine = machine(edits: true)
        let leaving = machine.handle(.dismissed)
        XCTAssertGreaterThan(leaving.to.translation, 0)

        let afterKeyboard = machine.handle(.keyboardMeasured(0))
        XCTAssertGreaterThan(
            afterKeyboard.to.translation, 0,
            "the keyboard reporting in cannot put a leaving tray back"
        )
    }

    func testATrayLeavingBesideTheKeyboardIsMeasuredFromWhereItWillBe() {
        var machine = machine(edits: true)
        let leaving = machine.handle(.dismissed)
        XCTAssertEqual(leaving.to.bottomInset, trayBottomMargin, "measured with the keyboard gone")
    }

    func testATrayLeavingBesideTheKeyboardBorrowsItsClock() {
        var machine = machine(edits: true)
        let timing = PinTrayMachine.KeyboardTiming(duration: 0.25, curve: 7)
        machine.keyboardTiming = timing
        XCTAssertEqual(machine.handle(.dismissed).timeline, .matching(timing))
    }

    func testATrayLeavingWithNoKeyboardUsesOurOwnSpring() {
        var machine = machine()
        machine.keyboardTiming = PinTrayMachine.KeyboardTiming(duration: 0.25, curve: 7)
        XCTAssertEqual(machine.handle(.dismissed).timeline, .spring(bounce: 0, initialVelocity: 0))
    }

    func testDismissingWhileEditingTakesTheKeyboardWithIt() {
        var machine = machine(edits: true)
        let gone = machine.handle(.dismissed)
        XCTAssertEqual(gone.effects, [.dismissKeyboard])
        XCTAssertTrue(gone.dismisses)
    }
}

extension PinTrayMachineTests {
    func testAHeightWithinHalfAPointOfWhereItStandsIsNotAResize() {
        let machine = machine(standing: 641)
        XCTAssertFalse(machine.resizes(to: 641), "the height it already stands at changes nothing")
        XCTAssertFalse(machine.resizes(to: 641.4), "nor does a measurement that lands on the same point")
        XCTAssertFalse(machine.resizes(to: 0), "and nothing has measured itself yet at zero")
        XCTAssertTrue(machine.resizes(to: 700), "a real change is one")
    }

    func testAReducedMotionPreferenceTakesTheZoomOutOfAMove() {
        var machine = machine()
        XCTAssertGreaterThan(machine.contentZoom, 1, "a move zooms the content it is leaving behind")

        machine.motionIsReduced = true
        XCTAssertEqual(machine.contentZoom, 1, "asked for less motion, the content crossfades in place")
    }
}

extension PinTrayMachineTests {
    func testTheMachineAddsUpAPullThatIsOnlyEverReportedInSlices() {
        var machine = machine()
        _ = machine.handle(.pulledFurther(10))
        _ = machine.handle(.pulledFurther(10))
        let third = machine.handle(.pulledFurther(10))

        XCTAssertEqual(
            third.to.translation,
            PinTrayGeometry.travel(forDrag: 30),
            accuracy: 0.5,
            "three tenths of the way down is thirty points from where it started"
        )
        XCTAssertTrue(machine.cardIsBeingPulled, "and the card knows it has the gesture")
    }

    func testAPullTakenAllTheWayBackHandsTheListOnward() {
        var machine = machine()
        _ = machine.handle(.pulledFurther(40))
        let back = machine.handle(.pulledFurther(-60))

        XCTAssertEqual(back.to.translation, 0, accuracy: 0.5, "the card is back where it stood")
        XCTAssertFalse(machine.cardIsBeingPulled, "so the gesture is the list's again")
    }
}

extension PinTrayMachineTests {
    func testAMoveThatNeverResolvedLeavesNothingBehindForTheNextTray() {
        var machine = machine(standing: 641)

        _ = machine.handle(.moveBegan(isPush: true))
        _ = machine.handle(.fillsReported(true))
        _ = machine.handle(.dismissed)
        _ = machine.handle(.caught(at: 0))

        let presented = machine.handle(.presented(contentHeight: 200))
        XCTAssertEqual(
            presented.to.height,
            200,
            accuracy: 1,
            "a tray that does not fill stands at its content's height, whatever a cancelled move said"
        )
    }
}

extension PinTrayMachineTests {
    func testMeasuringATrayDoesNotStandItBackUpOnceItIsLeaving() {
        var machine = machine(standing: 546)
        _ = machine.handle(.dismissed)
        let onItsWayOut = machine.geometry.translation

        let reported = machine.handle(.fillsReported(false))
        XCTAssertEqual(machine.phase, .leaving, "measuring what a tray holds does not cancel its exit")
        XCTAssertEqual(
            reported.to.translation, onItsWayOut, accuracy: 1,
            "and it keeps answering with where it is going: \(reported.to.translation) against \(onItsWayOut)"
        )

        let resized = machine.handle(.contentResized(387))
        XCTAssertEqual(
            resized.to.translation, onItsWayOut, accuracy: 1,
            "nor does measuring it again: \(resized.to.translation) against \(onItsWayOut)"
        )
    }
}

