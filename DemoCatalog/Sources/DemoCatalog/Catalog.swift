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
