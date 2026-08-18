import DemoCatalog
import SwiftUI

@MainActor
enum DemoPinwheelSections {
    static var all: [PinwheelSection] {
        [tokens, components, screens]
    }

    static var tokens: PinwheelSection {
        PinwheelSection(CatalogSection.tokens) {
            PinwheelItem(Catalog.typography) { PinTypographyDemo() }
            PinwheelItem(Catalog.color) { PinColorDemo() }
            PinwheelItem(Catalog.numbers) { PinNumbersDemo() }
            PinwheelItem(Catalog.typography, view: UIPinTypographyDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.color, view: UIPinColorDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.numbers, view: UIPinNumbersDemo.self).tags(.uiKit)
        }
    }

    static var components: PinwheelSection {
        PinwheelSection(CatalogSection.components) {
            PinwheelItem(Catalog.label) { PinLabelDemo() }
            PinwheelItem(Catalog.tweakable) { PinTweakableDemo() }
            PinwheelItem(Catalog.button) { PinButtonDemo() }
            PinwheelItem(Catalog.stepper) { PinStepperDemo() }
            PinwheelItem(Catalog.tray) { PinTrayDemo() }
            PinwheelItem(Catalog.stateView) { PinStateViewDemo() }
            PinwheelItem(Catalog.tableView) { PinTableViewDemo() }
            PinwheelItem(Catalog.label, view: UIPinLabelDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.tweakable, view: UIPinTweakableDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.button, view: UIPinButtonDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.stateView, view: UIPinStateViewDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.tableView, view: UIPinTableViewDemo.self).presentation(.medium).tags(.uiKit)
            PinwheelItem(Catalog.dataSourceTableView, view: UIPinDataSourceTableViewDemo.self).presentation(.medium).tags(.uiKit)
        }
    }

    static var screens: PinwheelSection {
        PinwheelSection(CatalogSection.screens) {
            PinwheelItem(Catalog.fullscreenView, view: UIPinFullscreenViewDemo.self).tags(.uiKit)
            PinwheelItem(Catalog.viewController, viewController: { UIPinViewControllerDemo() }).tags(.uiKit)
            PinwheelItem(Catalog.appleControls) { AppleControlsDemo() }.presentation(.fullscreen).tags(.figma)
            PinwheelItem(Catalog.collectionView, view: CollectionViewGridDemo.self).tags(.figma)
            PinwheelItem(Catalog.cards) { CardsDemo() }.tags(.figma)
            PinwheelItem(Catalog.lazyCards) { LazyCardsDemo() }.tags(.figma)
            PinwheelItem(Catalog.lazyGrid) { LazyGridDemo() }.tags(.figma)
            PinwheelItem(Catalog.sectionedList) { SectionedListDemo() }.tags(.figma)
            PinwheelItem(Catalog.productList) { ProductListDemo() }.tags(.figma)
            PinwheelItem(Catalog.pricing) { PricingDemo() }.tags(.figma)
            PinwheelItem(Catalog.cart) { CartDemo() }.tags(.figma)
            PinwheelItem(Catalog.orderSummary) { OrderSummaryDemo() }.tags(.figma)
            PinwheelItem(Catalog.imageGallery) { ImageGalleryDemo() }.tags(.figma)
            PinwheelItem(Catalog.pinList) { PinListDemo() }.tags(.figma)
        }
    }
}

#if DEBUG
private let previewComponentID = Catalog.numbers.id()

#Preview("Pinwheel Component") {
    PinwheelPreview(previewComponentID, sections: DemoPinwheelSections.all)
}
#endif
