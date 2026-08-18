import CoreGraphics
import Foundation

let trayResizeDuration: TimeInterval = 0.30
let trayResizeBounce: CGFloat = 0.10
let trayZoom: CGFloat = 1.08

struct PinTrayMachine: Equatable {
    enum Keyboard: Equatable {
        case closed
        case opening(height: CGFloat)
        case open(height: CGFloat)
        case closing

        var height: CGFloat {
            switch self {
            case .closed, .closing: return 0
            case .opening(let height), .open(let height): return height
            }
        }

        var ownsTheTimeline: Bool {
            switch self {
            case .opening, .closing: return true
            case .closed, .open: return false
            }
        }
    }

    enum Phase: Equatable {
        case arriving(Arriving)
        case awaitingKeyboard(Arriving)
        case standing
        case leaving

        var isResolvingAMove: Bool {
            switch self {
            case .arriving, .awaitingKeyboard: true
            case .standing, .leaving: false
            }
        }

        func reporting(_ arriving: Arriving) -> Phase {
            switch self {
            case .arriving: .arriving(arriving)
            case .awaitingKeyboard: .awaitingKeyboard(arriving)
            case .standing, .leaving: self
            }
        }
    }

    struct Arriving: Equatable {
        var contentHeight: CGFloat
        var fills: Bool
    }

    struct KeyboardTiming: Equatable {
        var duration: TimeInterval
        var curve: Int
    }

    enum Timeline: Equatable {
        case immediate
        case spring(bounce: CGFloat, initialVelocity: CGFloat)
        case carriedByKeyboard
        case matching(KeyboardTiming)
    }

    enum Effect: Equatable {
        case dismissKeyboard
    }

    enum Event: Equatable {
        case presented(contentHeight: CGFloat)
        case moved(contentHeight: CGFloat, edits: Bool, isPush: Bool)
        case moveBegan(isPush: Bool)
        case fillsReported(Bool)
        case contentResized(CGFloat)
        case keyboardMeasured(CGFloat)
        case dragged(CGFloat)
        case pulledFurther(CGFloat)
        case caught(at: CGFloat)
        case released(velocity: CGFloat)
        case dismissed
        case roomChanged(PinTrayGeometry.Room)
    }

    struct Reaction: Equatable {
        var from: PinTrayGeometry?
        var to: PinTrayGeometry
        var timeline: Timeline
        var effects: [Effect] = []
        var dismisses = false
    }

    private(set) var phase: Phase = .standing

    var isAwaitingKeyboard: Bool {
        if case .awaitingKeyboard = phase { return true }
        return false
    }
    private(set) var keyboard: Keyboard = .closed
    private(set) var contentHeight: CGFloat = 0
    private(set) var fills = false
    private(set) var edits = false
    private(set) var pulledSoFar: CGFloat = 0
    var dragOffset: CGFloat { PinTrayGeometry.travel(forDrag: pulledSoFar) }
    private(set) var room: PinTrayGeometry.Room
    var keyboardTiming: KeyboardTiming?

    var cardIsBeingPulled: Bool { pulledSoFar > 0 }

    init(room: PinTrayGeometry.Room) {
        self.room = room
    }

    var motionIsReduced = false
    var contentZoom: CGFloat { motionIsReduced ? 1 : trayZoom }

    func resizes(to height: CGFloat) -> Bool {
        height > 0 && abs(height - geometry.height) > 0.5
    }

    func keyboard(measuring height: CGFloat) -> Keyboard {
        let previous = keyboard.height
        guard height > 0 else { return previous > 0 ? .closing : .closed }
        return height == previous ? .open(height: height) : .opening(height: height)
    }

    private func geometry(_ phase: PinTrayGeometry.Phase) -> PinTrayGeometry {
        PinTrayGeometry(
            contentHeight: contentHeight,
            fills: fills,
            room: room,
            keyboardInset: keyboard.height,
            dragOffset: dragOffset,
            phase: phase,
            standsOnKeyboard: edits
        )
    }

    var geometry: PinTrayGeometry {
        geometry(phase == .leaving ? .leaving : .resting)
    }

    private mutating func recordForTheArrivingTray(_ event: Event) -> Bool {
        let report: Arriving
        switch phase {
        case .arriving(let arriving), .awaitingKeyboard(let arriving): report = arriving
        case .standing, .leaving: return false
        }
        switch event {
        case .fillsReported(let fills):
            phase = phase.reporting(Arriving(contentHeight: report.contentHeight, fills: fills))
            return true
        case .contentResized(let height):
            phase = phase.reporting(Arriving(contentHeight: height, fills: report.fills))
            return true
        default:
            return false
        }
    }

    private mutating func adoptWhatArrived() {
        switch phase {
        case .arriving(let arriving), .awaitingKeyboard(let arriving):
            contentHeight = arriving.contentHeight
            fills = arriving.fills
        case .standing, .leaving:
            break
        }
    }

    mutating func handle(_ event: Event) -> Reaction {
        let drawn = geometry
        var reaction = resolve(event)
        if reaction.from == nil, reaction.effects.isEmpty, !reaction.dismisses, reaction.to == drawn {
            reaction.timeline = .carriedByKeyboard
        }
        return reaction
    }

    private mutating func resolve(_ event: Event) -> Reaction {
        if phase.isResolvingAMove, recordForTheArrivingTray(event) {
            return Reaction(to: geometry(.resting), timeline: .carriedByKeyboard)
        }
        switch event {
        case .presented(let height):
            contentHeight = height
            phase = .standing
            return Reaction(from: geometry(.arriving), to: geometry(.resting), timeline: .spring(bounce: trayResizeBounce, initialVelocity: 0))

        case .moved(let height, let edits, let isPush):
            guard phase != .leaving else { return Reaction(to: geometry(.leaving), timeline: .carriedByKeyboard) }
            let wasEditing = self.edits
            let wasStanding = contentHeight
            let wasFilling = fills
            let arrivingFills = switch phase {
            case .arriving(let arriving), .awaitingKeyboard(let arriving): arriving.fills
            case .standing, .leaving: fills
            }
            contentHeight = height
            fills = arrivingFills
            self.edits = edits
            if isPush, edits, !arrivingFills, keyboard == .closed {
                contentHeight = wasStanding
                fills = wasFilling
                phase = .awaitingKeyboard(Arriving(contentHeight: height, fills: arrivingFills))
                return Reaction(to: geometry(.resting), timeline: .carriedByKeyboard)
            }
            phase = .standing
            let dismissesKeyboard = !isPush && wasEditing && keyboard != .closed
            if dismissesKeyboard {
                keyboard = .closing
                self.edits = false
            }
            return Reaction(
                to: geometry(.resting),
                timeline: .spring(bounce: trayResizeBounce, initialVelocity: 0),
                effects: dismissesKeyboard ? [.dismissKeyboard] : []
            )

        case .keyboardMeasured(let height):
            keyboard = keyboard(measuring: height)
            guard phase != .leaving else {
                return Reaction(to: geometry(.leaving), timeline: .carriedByKeyboard)
            }
            var waited = false
            if case .awaitingKeyboard = phase {
                waited = true
                adoptWhatArrived()
                phase = .standing
            }
            return Reaction(
                to: geometry(.resting),
                timeline: keyboard.ownsTheTimeline || waited ? .carriedByKeyboard : .spring(bounce: 0, initialVelocity: 0)
            )

        case .roomChanged(let room):
            self.room = room
            return Reaction(to: geometry(phase == .leaving ? .leaving : .resting), timeline: .carriedByKeyboard)

        case .moveBegan:
            guard phase != .leaving else { return Reaction(to: geometry(.leaving), timeline: .carriedByKeyboard) }
            phase = .arriving(Arriving(contentHeight: contentHeight, fills: fills))
            return Reaction(to: geometry(.resting), timeline: .carriedByKeyboard)

        case .fillsReported(let fills):
            self.fills = fills
            guard phase != .leaving else { return Reaction(to: geometry(.leaving), timeline: .carriedByKeyboard) }
            return Reaction(to: geometry(.resting), timeline: .spring(bounce: 0, initialVelocity: 0))

        case .contentResized(let height):
            guard !fills else { return Reaction(to: geometry(.resting), timeline: .spring(bounce: 0, initialVelocity: 0)) }
            guard phase != .leaving else { return Reaction(to: geometry(.leaving), timeline: .carriedByKeyboard) }
            contentHeight = height
            return Reaction(to: geometry(.resting), timeline: .spring(bounce: 0, initialVelocity: 0))

        case .dragged(let offset):
            pulledSoFar = offset
            return Reaction(to: geometry(.resting), timeline: .immediate)

        case .pulledFurther(let slice):
            pulledSoFar = max(0, pulledSoFar + slice)
            return Reaction(to: geometry(.resting), timeline: .immediate)

        case .caught(let translation):
            phase = .standing
            pulledSoFar = max(0, translation)
            return Reaction(to: geometry(.resting), timeline: .immediate)

        case .released(let velocity):
            let travelled = dragOffset
            pulledSoFar = 0
            let lands = travelled + PinTrayGeometry.coast(atSpeed: velocity)
            guard lands > geometry(.leaving).translation / 2 else {
                let resting = geometry(.resting)
                return Reaction(
                    to: resting,
                    timeline: .spring(
                        bounce: trayResizeBounce,
                        initialVelocity: PinTrayGeometry.springVelocity(
                            travelling: resting.translation - travelled,
                            releasedAt: velocity
                        )
                    )
                )
            }
            phase = .leaving
            let leaving = geometry(.leaving)
            return Reaction(
                to: leaving,
                timeline: .spring(
                    bounce: 0,
                    initialVelocity: PinTrayGeometry.springVelocity(
                        travelling: leaving.translation - travelled,
                        releasedAt: velocity
                    )
                ),
                dismisses: true
            )

        case .dismissed:
            phase = .leaving
            let takesTheKeyboardWithIt = keyboard != .closed
            if takesTheKeyboardWithIt {
                keyboard = .closing
                edits = false
            }
            let timeline: Timeline = takesTheKeyboardWithIt
                ? keyboardTiming.map(Timeline.matching) ?? .spring(bounce: 0, initialVelocity: 0)
                : .spring(bounce: 0, initialVelocity: 0)
            return Reaction(
                to: geometry(.leaving),
                timeline: timeline,
                effects: takesTheKeyboardWithIt ? [.dismissKeyboard] : [],
                dismisses: true
            )
        }
    }
}
