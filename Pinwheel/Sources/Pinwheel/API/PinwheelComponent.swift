import SwiftUI
import UIKit

/// A `String`-backed enum whose `rawValue` is the component's display title.
public protocol PinwheelComponent: RawRepresentable where RawValue == String {}

public extension PinwheelComponent {
    /// Matches the id of the `PinwheelItem` built from this name. `Catalog.stateView.id(.uiKit) == "uikit-stateview"`.
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
