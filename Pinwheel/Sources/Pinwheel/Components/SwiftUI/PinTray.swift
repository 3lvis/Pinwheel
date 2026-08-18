import SwiftUI

/// One screen of a tray flow: a title, a body, and optionally something floating over that body
/// and a button that ends the flow.
public struct PinTray {
    /// How tall a tray stands: as tall as what it holds, or as tall as the room there is.
    public enum Detent {
        case fitting
        case filling
    }

    struct Commit {
        let title: String
        let action: () -> Void
    }

    let title: String
    let content: AnyView
    private(set) var titleAccessory: AnyView?
    private(set) var floating: AnyView?
    private(set) var commit: Commit?
    private(set) var detent: Detent = .fitting

    public init<Content: SwiftUI.View>(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = AnyView(VStack(spacing: traySectionGap) { content() })
    }

    /// Defaults to `.fitting`.
    public func detent(_ detent: Detent) -> PinTray {
        var copy = self
        copy.detent = detent
        return copy
    }

    /// A control at the trailing end of the title bar. The leading end is the way out and is not
    /// yours to set: a cross at the root of a flow, a back chevron once pushed.
    public func titleAccessory<Accessory: SwiftUI.View>(@ViewBuilder _ accessory: () -> Accessory) -> PinTray {
        var copy = self
        copy.titleAccessory = AnyView(accessory())
        return copy
    }

    /// Something that stands over the body at the tray's bottom edge, which the body scrolls behind.
    /// Takes precedence over `commit(_:action:)`.
    public func floating<Floating: SwiftUI.View>(@ViewBuilder _ floating: () -> Floating) -> PinTray {
        var copy = self
        copy.floating = AnyView(floating())
        return copy
    }

    /// The button that ends the flow. Leave it off where a tap already takes effect.
    public func commit(_ title: String, action: @escaping () -> Void) -> PinTray {
        var copy = self
        copy.commit = Commit(title: title, action: action)
        return copy
    }
}

public extension Animation {
    static let trayContent = Animation.spring(duration: 0.30, bounce: 0.10)
}
