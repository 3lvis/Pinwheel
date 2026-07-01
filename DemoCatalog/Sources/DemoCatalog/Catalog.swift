@_exported import Pinwheel

/// The demo catalog's component names — the single source of truth for titles,
/// shared by the Demo app (which builds the catalog) and DemoUITests (which
/// deep-links to a component). Re-exports Pinwheel so importing `DemoCatalog` is
/// all either target needs (`PinTag`, `PinwheelItem`, … come along).
public enum Catalog: String, PinwheelComponent {
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
}

public enum CatalogSection: String {
    case tokens = "Tokens"
    case components = "Components"
    case screens = "Screens"
}
