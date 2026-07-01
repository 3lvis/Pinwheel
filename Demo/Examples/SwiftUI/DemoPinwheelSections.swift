import Pinwheel
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, recyclable, uikit]
    }

    static var tokens: PinwheelSection {
        PinwheelSection("Tokens", id: "tokens") {
            PinwheelItem("Font", id: "font") {
                PinFontExample()
            }

            PinwheelItem("Color", id: "color") {
                PinColorExample()
            }

            PinwheelItem("Spacing", id: "spacing") {
                PinSpacingExample()
            }
        }
    }

    static var components: PinwheelSection {
        PinwheelSection("Components", id: "components") {
            PinwheelItem("Label", id: "label") {
                PinLabelExample()
            }

            PinwheelItem("Tweakable", id: "tweakable") {
                PinTweakableExample()
            }

            PinwheelItem("Button", id: "button") {
                PinButtonExample()
            }

            PinwheelItem("StateView", id: "state-view") {
                PinStateViewExample()
            }
        }
    }

    static var recyclable: PinwheelSection {
        PinwheelSection("Recyclable", id: "recyclable") {
            PinwheelItem("TableView", id: "table-view") {
                PinTableViewExample()
            }
            .presentation(.medium)
        }
    }

    static var uikit: PinwheelSection {
        PinwheelSection("UIKit", id: "uikit") {
            PinwheelItem("UIKit Font", id: "uikit-font", view: UIKitPinFontExample.self)
            PinwheelItem("UIKit Color", id: "uikit-color", view: UIKitPinColorExample.self)
            PinwheelItem("UIKit Spacing", id: "uikit-spacing", view: UIKitPinSpacingExample.self)
            PinwheelItem("UIKit Label", id: "uikit-label", view: UIKitPinLabelExample.self)
            PinwheelItem("UIKit Tweakable", id: "uikit-tweakable", view: UIKitPinTweakableExample.self)
            PinwheelItem("UIKit FullscreenView", id: "uikit-fullscreen-view", view: UIKitPinFullscreenViewExample.self)
            PinwheelItem("UIKit Button", id: "uikit-button", view: UIKitPinButtonExample.self)
            PinwheelItem("UIKit StateView", id: "uikit-state-view", view: UIKitPinStateViewExample.self)
            PinwheelItem("UIKit TableView", id: "uikit-table-view", view: UIKitPinTableViewExample.self)
                .presentation(.medium)
            PinwheelItem("UIKit DataSource TableView", id: "uikit-datasource-table-view", view: UIKitPinDataSourceTableViewExample.self)
                .presentation(.medium)
            PinwheelItem("UIKit ViewController", id: "uikit-view-controller", viewController: { UIKitPinViewControllerExample() })
        }
    }
}

#if DEBUG
/// Fast visual iteration on any catalog component, no throwaway `#Preview`
/// needed: change `previewComponentID` to any id below and render this preview.
/// Ids are bare (`"button"`) or qualified (`"components/button"`); an unknown id
/// renders a list of every available id. For a running simulator instead,
/// deep-link the Demo: `simctl launch <bundle> -PinwheelPreview button`.
private let previewComponentID = "uikit-fullscreen-view"

#Preview("Pinwheel Component") {
    PinwheelPreview(previewComponentID, sections: DemoPinwheelSections.all)
}
#endif
