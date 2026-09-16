import SwiftUI
import UIKit

public struct PinwheelCatalog: SwiftUI.View {
    private let sections: [PinwheelSection]
    private let usesEmbeddedNavigation: Bool
    private let themes: [PinwheelTheme]

    public init(usesEmbeddedNavigation: Bool = true, @PinwheelSectionBuilder sections: () -> [PinwheelSection]) {
        self.init(
            themes: [.standard],
            usesEmbeddedNavigation: usesEmbeddedNavigation,
            sections: sections
        )
    }

    public init(
        themes: [PinwheelTheme],
        usesEmbeddedNavigation: Bool = true,
        @PinwheelSectionBuilder sections: () -> [PinwheelSection]
    ) {
        self.sections = sections()
        self.usesEmbeddedNavigation = usesEmbeddedNavigation
        self.themes = themes
    }

    public var body: some SwiftUI.View {
        PinwheelCatalogView(
            sections: sections,
            usesEmbeddedNavigation: usesEmbeddedNavigation,
            themes: themes
        )
    }
}
