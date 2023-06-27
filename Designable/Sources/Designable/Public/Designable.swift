@_exported import UIKit

public enum TabletDisplayMode {
    case master
    case detail
    case fullscreen
}

public struct DesignableSection {
    public let title: String
    public let items: [DesignableItem]

    public init(title: String, items: [DesignableItem]) {
        self.title = title
        self.items = items
    }

    func capitalizedTitles() -> [String] {
        return items.map { $0.title.capitalizingFirstLetter }
    }
}

public struct DesignableItem {
    public let title: String
    public let viewController: UIViewController
    public let tabletDisplayMode: TabletDisplayMode

    public init(title: String, viewController: UIViewController, tabletDisplayMode: TabletDisplayMode = .fullscreen) {
        self.title = title
        self.viewController = viewController
        self.tabletDisplayMode = tabletDisplayMode
    }
}
