@_exported import Pinwheel

public enum Catalog: String, PinwheelComponent {
    case typography = "Typography"
    case color = "Color"
    case numbers = "Numbers"
    case label = "Label"
    case button = "Button"
    case tweakable = "Tweakable"
    case stateView = "StateView"
    case tableView = "TableView"
    case dataSourceTableView = "DataSource TableView"
    case collectionView = "CollectionView"
    case cards = "Cards"
    case lazyCards = "Lazy Cards"
    case lazyGrid = "Lazy Grid"
    case sectionedList = "Sectioned List"
    case productList = "Product List"
    case pricing = "Pricing"
    case cart = "Cart"
    case imageGallery = "Image Gallery"
    case pinList = "Pin List"
    case fullscreenView = "FullscreenView"
    case viewController = "ViewController"
    case appleControls = "Apple Controls"
}

public enum CatalogSection: String {
    case tokens = "Tokens"
    case components = "Components"
    case screens = "Screens"
}

public extension PinTag {
    nonisolated static let figma = PinTag(rawValue: "Figma")
}
