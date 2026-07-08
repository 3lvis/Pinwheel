import DemoCatalog
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, screens]
    }

    static var tokens: PinwheelSection {
        PinwheelSection(CatalogSection.tokens) {
            PinwheelItem(Catalog.typography) { PinTypographyDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.color) { PinColorDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.numbers) { PinNumbersDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.typography, view: UIKitPinTypographyDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.color, view: UIKitPinColorDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.numbers, view: UIKitPinNumbersDemo.self).tags(.uiKit)
        }
    }

    static var components: PinwheelSection {
        PinwheelSection(CatalogSection.components) {
            PinwheelItem(Catalog.label) { PinLabelDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.tweakable) { PinTweakableDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.button) { PinButtonDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.stateView) { PinStateViewDemo() }.tags(.swiftUI)
            PinwheelItem(Catalog.tableView) { PinTableViewDemo() }.tags(.swiftUI)
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
        }
    }
}

#if DEBUG
private let previewComponentID = Catalog.numbers.id(.swiftUI)

#Preview("Pinwheel Component") {
    PinwheelPreview(previewComponentID, sections: DemoPinwheelSections.all)
}
#endif
