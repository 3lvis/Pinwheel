import DemoCatalog
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, screens]
    }

    static var tokens: PinwheelSection {
        PinwheelSection(CatalogSection.tokens) {
            PinwheelItem(Catalog.font) { PinFontDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.color) { PinColorDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.spacing) { PinSpacingDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.font, view: UIKitPinFontDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.color, view: UIKitPinColorDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.spacing, view: UIKitPinSpacingDemo.self).tags(.uiKit)
        }
    }

    static var components: PinwheelSection {
        PinwheelSection(CatalogSection.components) {
            PinwheelItem(Catalog.label) { PinLabelDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.tweakable) { PinTweakableDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.button) { PinButtonDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.stateView) { PinStateViewDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.tableView) { PinTableViewDemo() }.presentation(.medium).tags(.swiftUI)
            PinwheelItem(Catalog.label, view: UIKitPinLabelDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.tweakable, view: UIKitPinTweakableDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.button, view: UIKitPinButtonDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.stateView, view: UIKitPinStateViewDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.tableView, view: UIKitPinTableViewDemo.self).presentation(.medium).tags(.uiKit)
            PinwheelItem(Catalog.dataSourceTableView, view: UIKitPinDataSourceTableViewDemo.self).presentation(.medium).tags(.uiKit)
        }
    }

    static var screens: PinwheelSection {
        PinwheelSection(CatalogSection.screens) {
            PinwheelItem(Catalog.fullscreenView, view: UIKitPinFullscreenViewDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.viewController, viewController: { UIKitPinViewControllerDemo() }).tags(.uiKit)
            PinwheelItem(Catalog.appleControls) { AppleControlsDemo() }.presentation(.fullscreen).tags(.figma)
            PinwheelItem(Catalog.buttonLayout) { PinButtonLayoutDemo() }.tags(.figma)
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
