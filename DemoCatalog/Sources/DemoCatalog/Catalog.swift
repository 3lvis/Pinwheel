@_exported import Pinwheel

// A shared module because a UI-test target can't import the app, yet both the
// Demo and DemoUITests need these component names to agree.
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
