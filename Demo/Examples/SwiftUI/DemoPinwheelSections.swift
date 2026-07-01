import Pinwheel
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, screens]
    }

    static var tokens: PinwheelSection {
        PinwheelSection(.tokens) {
            PinwheelItem(.font) { PinFontExample() }.tags(.swiftUI)
            PinwheelItem(.color) { PinColorExample() }.tags(.swiftUI)
            PinwheelItem(.spacing) { PinSpacingExample() }.tags(.swiftUI)
            PinwheelItem(.font, view: UIKitPinFontExample.self).tags(.uiKit)
            PinwheelItem(.color, view: UIKitPinColorExample.self).tags(.uiKit)
            PinwheelItem(.spacing, view: UIKitPinSpacingExample.self).tags(.uiKit)
        }
    }

    static var components: PinwheelSection {
        PinwheelSection(.components) {
            PinwheelItem(.label) { PinLabelExample() }.tags(.swiftUI)
            PinwheelItem(.tweakable) { PinTweakableExample() }.tags(.swiftUI)
            PinwheelItem(.button) { PinButtonExample() }.tags(.swiftUI)
            PinwheelItem(.stateView) { PinStateViewExample() }.tags(.swiftUI)
            PinwheelItem(.tableView) { PinTableViewExample() }.presentation(.medium).tags(.swiftUI)
            PinwheelItem(.label, view: UIKitPinLabelExample.self).tags(.uiKit)
            PinwheelItem(.tweakable, view: UIKitPinTweakableExample.self).tags(.uiKit)
            PinwheelItem(.button, view: UIKitPinButtonExample.self).tags(.uiKit)
            PinwheelItem(.stateView, view: UIKitPinStateViewExample.self).tags(.uiKit)
            PinwheelItem(.tableView, view: UIKitPinTableViewExample.self).presentation(.medium).tags(.uiKit)
            PinwheelItem(.dataSourceTableView, view: UIKitPinDataSourceTableViewExample.self).presentation(.medium).tags(.uiKit)
        }
    }

    static var screens: PinwheelSection {
        PinwheelSection(.screens) {
            PinwheelItem(.fullscreenView, view: UIKitPinFullscreenViewExample.self).tags(.uiKit)
            PinwheelItem(.viewController, viewController: { UIKitPinViewControllerExample() }).tags(.uiKit)
        }
    }
}

#if DEBUG
/// Fast visual iteration on any catalog component, no throwaway `#Preview`
/// needed: change `previewComponentID` to any id below and render this preview.
/// Ids are bare (`"swiftui-button"`) or qualified (`"components/swiftui-button"`);
/// an unknown id renders a list of every available id. For a running simulator
/// instead, deep-link the Demo: `simctl launch <bundle> -PinwheelPreview swiftui-button`.
private let previewComponentID = Component.fullscreenView.id(.uiKit)

#Preview("Pinwheel Component") {
    PinwheelPreview(previewComponentID, sections: DemoPinwheelSections.all)
}
#endif
