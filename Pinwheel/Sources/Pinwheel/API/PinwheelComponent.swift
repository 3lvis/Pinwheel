import SwiftUI
import UIKit

/// A `String`-backed enum whose `rawValue` is the component's display title.
public protocol PinwheelComponent: RawRepresentable where RawValue == String {}

extension PinwheelComponent {
    /// Matches the id of the `PinwheelItem` built from this name. `Catalog.stateView.id(.uiKit) == "uikit-stateview"`.
    public nonisolated func id(_ tags: PinTag...) -> String {
        return PinwheelItem.generatedID(title: rawValue, tags: tags)
    }
}

extension PinwheelItem {
    public init<Name: PinwheelComponent, Content: SwiftUI.View>(_ name: Name, @ViewBuilder content: @escaping () -> Content) {
        self.init(name.rawValue, content: content)
    }

    public init<Name: PinwheelComponent, ViewType: UIView>(_ name: Name, view: ViewType.Type) {
        self.init(name.rawValue, view: view)
    }

    public init<Name: PinwheelComponent>(_ name: Name, viewController: @escaping () -> UIViewController) {
        self.init(name.rawValue, viewController: viewController)
    }
}

extension PinwheelSection {
    public init<Name: RawRepresentable>(_ name: Name, @PinwheelItemBuilder items: () -> [PinwheelItem]) where Name.RawValue == String {
        self.init(name.rawValue, items: items)
    }
}
