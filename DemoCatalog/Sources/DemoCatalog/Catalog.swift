@_exported import Pinwheel

public enum Catalog: String, PinwheelComponent {
    case font = "Font"
    case color = "Color"
    case dimensions = "Dimensions"
    case label = "Label"
    case button = "Button"
    case buttonLayout = "Button Layout"
    case tweakable = "Tweakable"
    case stateView = "StateView"
    case tableView = "TableView"
    case dataSourceTableView = "DataSource TableView"
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
