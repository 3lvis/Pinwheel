import DemoCatalog
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, screens]
    }

    static var tokens: PinwheelSection {
        PinwheelSection(CatalogSection.tokens) {
            PinwheelItem(Catalog.font) { PinFontExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.color) { PinColorExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.spacing) { PinSpacingExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.font, view: UIKitPinFontExample.self).tags(.uiKit)
            PinwheelItem(Catalog.color, view: UIKitPinColorExample.self).tags(.uiKit)
            PinwheelItem(Catalog.spacing, view: UIKitPinSpacingExample.self).tags(.uiKit)
        }
    }

    static var components: PinwheelSection {
        PinwheelSection(CatalogSection.components) {
            PinwheelItem(Catalog.label) { PinLabelExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.tweakable) { PinTweakableExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.button) { PinButtonExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.stateView) { PinStateViewExample() }.tags(.swiftUI)
            PinwheelItem(Catalog.tableView) { PinTableViewExample() }.presentation(.medium).tags(.swiftUI)
            PinwheelItem(Catalog.label, view: UIKitPinLabelExample.self).tags(.uiKit)
            PinwheelItem(Catalog.tweakable, view: UIKitPinTweakableExample.self).tags(.uiKit)
            PinwheelItem(Catalog.button, view: UIKitPinButtonExample.self).tags(.uiKit)
            PinwheelItem(Catalog.stateView, view: UIKitPinStateViewExample.self).tags(.uiKit)
            PinwheelItem(Catalog.tableView, view: UIKitPinTableViewExample.self).presentation(.medium).tags(.uiKit)
            PinwheelItem(Catalog.dataSourceTableView, view: UIKitPinDataSourceTableViewExample.self).presentation(.medium).tags(.uiKit)
        }
    }

    static var screens: PinwheelSection {
        PinwheelSection(CatalogSection.screens) {
            PinwheelItem(Catalog.fullscreenView, view: UIKitPinFullscreenViewExample.self).tags(.uiKit)
            PinwheelItem(Catalog.viewController, viewController: { UIKitPinViewControllerExample() }).tags(.uiKit)
            PinwheelItem(Catalog.appleControls) { AppleControlsGallery() }.presentation(.fullscreen).tags(.figma)
        }
    }
}

#if DEBUG
// Change to any catalog id and render the preview below; an unknown id renders a
// list of every available id.
private let previewComponentID = Catalog.fullscreenView.id(.uiKit)

#Preview("Pinwheel Component") {
    PinwheelPreview(previewComponentID, sections: DemoPinwheelSections.all)
}
#endif
