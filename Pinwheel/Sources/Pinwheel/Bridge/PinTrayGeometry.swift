import CoreGraphics

let trayMargin: CGFloat = .spacing2
let trayBottomMargin: CGFloat = .spacing2
let trayKeyboardMargin: CGFloat = .spacing4
let trayTopRadius: CGFloat = 32
let traySectionGap: CGFloat = .spacing5
let trayItemGap: CGFloat = .spacing3
let trayContentMargin: CGFloat = .spacing5
let trayLift: CGFloat = .spacing8
let trayRubberBanding: CGFloat = 0.55
let trayDecelerationRate: CGFloat = 0.99
let trayThrowSpeed: CGFloat = 250
let traySpringLaunchCeiling: CGFloat = 10 / trayResizeDuration
let trayBackdropReach: CGFloat = .minimumControlHeight

struct PinTrayGeometry: Equatable {
    enum Phase: Equatable {
        case arriving
        case resting
        case leaving
    }

    struct Room: Equatable {
        var containerHeight: CGFloat
        var safeAreaTop: CGFloat
        var safeAreaBottom: CGFloat
        var displayCornerRadius: CGFloat

        init(
            containerHeight: CGFloat,
            safeAreaTop: CGFloat = 0,
            safeAreaBottom: CGFloat = 0,
            displayCornerRadius: CGFloat = .radiusL
        ) {
            self.containerHeight = containerHeight
            self.safeAreaTop = safeAreaTop
            self.safeAreaBottom = safeAreaBottom
            self.displayCornerRadius = displayCornerRadius
        }
    }

    let height: CGFloat
    let bottomInset: CGFloat
    let translation: CGFloat
    let contentBottomInset: CGFloat
    let bottomCornerRadius: CGFloat
    let clearanceAboveGuide: CGFloat

    /// How much the backdrop under the card holds. Derived from where the card is rather than stored
    /// beside it: the backdrop is a different view, and what places the card is what decides whether a
    /// reaction has anything to animate.
    var dimming: CGFloat {
        let travelToGone = height + bottomInset
        let gone = travelToGone > 0 ? translation / travelToGone : 0
        return 1 - min(1, max(0, gone))
    }

    static func clearanceAboveAccessory(floats: Bool) -> CGFloat {
        floats ? .spacing2 : traySectionGap
    }

    init(
        contentHeight: CGFloat,
        fills: Bool = false,
        room: Room,
        keyboardInset: CGFloat = 0,
        dragOffset: CGFloat = 0,
        phase: Phase = .resting,
        standsOnKeyboard: Bool = true
    ) {
        let lifted = keyboardInset > 0 && standsOnKeyboard
        bottomInset = max(trayBottomMargin, lifted ? keyboardInset + trayKeyboardMargin : 0)
        bottomCornerRadius = lifted ? trayTopRadius : room.displayCornerRadius
        clearanceAboveGuide = bottomInset - keyboardInset

        let available = room.containerHeight - room.safeAreaTop - trayBackdropReach - bottomInset
        height = max(0, fills ? available : min(contentHeight, available))

        contentBottomInset = max(room.safeAreaBottom - trayBottomMargin, .spacing4)

        switch phase {
        case .arriving, .leaving:
            translation = height + bottomInset
        case .resting:
            translation = dragOffset
        }

    }
}

extension PinTrayGeometry {
    static func travel(forDrag offset: CGFloat) -> CGFloat {
        guard offset < 0 else { return offset }
        let pulled = -offset * trayRubberBanding
        return -(pulled * trayLift / (trayLift + pulled))
    }
}

extension PinTrayGeometry {
    static func coast(atSpeed velocity: CGFloat) -> CGFloat {
        guard abs(velocity) >= trayThrowSpeed else { return 0 }
        return velocity * trayDecelerationRate / (1 - trayDecelerationRate)
    }
}

extension PinTrayGeometry {
    static func springVelocity(travelling: CGFloat, releasedAt velocity: CGFloat) -> CGFloat {
        guard travelling != 0 else { return 0 }
        let crossingsPerSecond = velocity / travelling
        return min(max(crossingsPerSecond, -traySpringLaunchCeiling), traySpringLaunchCeiling)
    }
}
