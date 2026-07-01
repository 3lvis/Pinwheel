import Pinwheel
import SwiftUI
import UIKit

/// Typed names for the demo catalog — the single source of truth for a
/// component's display title (`rawValue`). The catalog id derives from the title
/// plus any tags via `PinwheelItem.generatedID`, so `PinwheelItem(.font)` reads
/// typed at the call site and no title/id string is repeated.
enum Component: String {
    case font = "Font"
    case color = "Color"
    case spacing = "Spacing"
    case label = "Label"
    case button = "Button"
    case tweakable = "Tweakable"
    case stateView = "StateView"
    case tableView = "TableView"
    case dataSourceTableView = "DataSource TableView"
    case fullscreenView = "FullscreenView"
    case viewController = "ViewController"

    /// The deep-link id this component resolves to under the given tags —
    /// `Component.fullscreenView.id(.uiKit) == "uikit-fullscreenview"`.
    func id(_ tags: PinTag...) -> String {
        return PinwheelItem.generatedID(title: rawValue, tags: tags)
    }
}

enum CatalogSection: String {
    case tokens = "Tokens"
    case components = "Components"
    case screens = "Screens"
}

// Typed convenience inits over the demo's own enums. UIKit-hosting overloads
// (`view:`/`viewController:`) name UIKit types, so this bridge file imports UIKit.
@MainActor
extension PinwheelItem {
    init<Content: SwiftUI.View>(_ component: Component, @ViewBuilder content: @escaping () -> Content) {
        self.init(component.rawValue, content: content)
    }

    init<ViewType: UIView>(_ component: Component, view: ViewType.Type) {
        self.init(component.rawValue, view: view)
    }

    init(_ component: Component, viewController: @escaping () -> UIViewController) {
        self.init(component.rawValue, viewController: viewController)
    }
}

@MainActor
extension PinwheelSection {
    init(_ section: CatalogSection, @PinwheelItemBuilder items: () -> [PinwheelItem]) {
        self.init(section.rawValue, items: items)
    }
}
