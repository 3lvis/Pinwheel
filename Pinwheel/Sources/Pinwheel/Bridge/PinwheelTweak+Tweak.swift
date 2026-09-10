import SwiftUI
import UIKit

extension PinwheelTweak {
    init?(_ tweak: Tweak) {
        if let text = tweak as? TextTweak {
            self.init(text.title, description: text.description, action: text.action)
        } else if let toggle = tweak as? BoolTweak {
            // Back the toggle with captured locals, not a class: a @MainActor class
            // (the package's default isolation) has an isolated deinit that hops to
            // the main actor on release and deadlocks when ARC frees it off-main
            // (e.g. XCTest teardown on a headless CI runner).
            let action = toggle.action
            var isOn = toggle.isOn
            self.init(
                toggle.title,
                description: toggle.description,
                isOn: Binding(get: { isOn }, set: { isOn = $0; action($0) })
            )
        } else if let select = tweak as? SelectTweak {
            self.init(
                select.title,
                description: select.description,
                options: select.options,
                selection: Binding(
                    get: { select.chosenOption() },
                    set: { select.action($0) }
                )
            )
        } else {
            return nil
        }
    }
}

/// A `UIViewControllerRepresentable` rather than a `UIViewRepresentable`: SwiftUI hands a controller the
/// full proposed size, where a view sizes to its fitting size and collapses edge-pinned content to the
