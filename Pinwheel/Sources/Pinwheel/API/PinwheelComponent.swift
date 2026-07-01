import SwiftUI
import UIKit

/// A consumer's catalog component name: a `String`-backed enum whose `rawValue`
/// is the display title. Conforming gives typed `PinwheelItem` creation
/// (`PinwheelItem(MyComponent.button)`) and a deep-link `id(_:)` — the same id
/// the built item resolves to — so previews and UI tests reference components
/// without a hardcoded slug string. Define it in a module your app *and* its
/// UI-test target import (a UI-test target runs in a separate process and can't
/// `@testable import` the app), and both sides stay in sync from one source.
public protocol PinwheelComponent: RawRepresentable where RawValue == String {}

public extension PinwheelComponent {
    /// The deep-link id this component resolves to under `tags` — matches the
    /// id of the `PinwheelItem` built from it, so `-PinwheelPreview <id>` needs
    /// no hardcoded slug. `Catalog.stateView.id(.uiKit) == "uikit-stateview"`.
    nonisolated func id(_ tags: PinTag...) -> String {
        return PinwheelItem.generatedID(title: rawValue, tags: tags)
    }
}

public extension PinwheelItem {
    init<Name: PinwheelComponent, Content: SwiftUI.View>(_ name: Name, @ViewBuilder content: @escaping () -> Content) {
        self.init(name.rawValue, content: content)
    }

    init<Name: PinwheelComponent, ViewType: UIView>(_ name: Name, view: ViewType.Type) {
        self.init(name.rawValue, view: view)
    }

    init<Name: PinwheelComponent>(_ name: Name, viewController: @escaping () -> UIViewController) {
        self.init(name.rawValue, viewController: viewController)
    }
}

public extension PinwheelSection {
    init<Name: RawRepresentable>(_ name: Name, @PinwheelItemBuilder items: () -> [PinwheelItem]) where Name.RawValue == String {
        self.init(name.rawValue, items: items)
    }
}
