import Foundation
import SwiftUI

/// Renders a single catalog component in isolation, resolved by id — the same
/// isolated render the catalog shows when an item is opened, with no navigation
/// scaffolding. This is the preview index: the existing `PinwheelSection`/
/// `PinwheelItem` registry doubles as the list of previewable components, so a
/// component becomes previewable the moment it is added to the catalog.
///
/// Two iteration paths build on this:
/// - SwiftUI `#Preview` — `PinwheelPreview("button", sections: ...)`.
/// - Deep-linking a host app straight to one component, bypassing the catalog
///   (see `requestedID`): `simctl launch <bundle> -PinwheelPreview button`.
///
/// `id` accepts either a bare item id (`"button"`) or a qualified
/// `"sectionID/itemID"` (`"components/button"`) to disambiguate items that share
/// an id across sections.
public struct PinwheelPreview: SwiftUI.View {
    private let sections: [PinwheelSection]
    private let id: String

    public init(_ id: String, sections: [PinwheelSection]) {
        self.id = id
        self.sections = sections
    }

    public init(_ id: String, @PinwheelSectionBuilder sections: () -> [PinwheelSection]) {
        self.init(id, sections: sections())
    }

    public var body: some SwiftUI.View {
        if let match = PinwheelPreviewResolver.resolve(id: id, in: sections) {
            PinwheelPlayground(
                item: match.item,
                selection: PinwheelSelection(sectionID: match.section.id, itemID: match.item.id)
            ) {}
        } else {
            PinwheelPreviewNotFound(requestedID: id, sections: sections)
        }
    }
}

public extension PinwheelPreview {
    /// The component id requested for an isolated preview launch, if any — read
    /// from the `-PinwheelPreview <id>` launch argument or the
    /// `PINWHEEL_PREVIEW` environment variable. A host app branches on this to
    /// deep-link straight to one component:
    ///
    /// ```swift
    /// if let id = PinwheelPreview.requestedID {
    ///     PinwheelPreview(id, sections: allSections)
    /// } else {
    ///     PinwheelCatalog { ... }
    /// }
    /// ```
    static var requestedID: String? {
        // UserDefaults surfaces `-PinwheelPreview <value>` launch arguments.
        if let argument = UserDefaults.standard.string(forKey: "PinwheelPreview"),
           !argument.isEmpty {
            return argument
        }

        if let environment = ProcessInfo.processInfo.environment["PINWHEEL_PREVIEW"],
           !environment.isEmpty {
            return environment
        }

        return nil
    }
}

enum PinwheelPreviewResolver {
    static func resolve(
        id rawID: String,
        in sections: [PinwheelSection]
    ) -> (section: PinwheelSection, item: PinwheelItem)? {
        let trimmed = rawID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let slash = trimmed.firstIndex(of: "/") {
            let sectionID = String(trimmed[..<slash])
            let itemID = String(trimmed[trimmed.index(after: slash)...])
            guard let section = sections.first(where: { $0.id == sectionID }),
                  let item = section.items.first(where: { $0.id == itemID }) else {
                return nil
            }
            return (section, item)
        }

        for section in sections {
            if let item = section.items.first(where: { $0.id == trimmed }) {
                return (section, item)
            }
        }

        return nil
    }
}

private struct PinwheelPreviewNotFound: SwiftUI.View {
    let requestedID: String
    let sections: [PinwheelSection]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingL) {
                Text("No component with id “\(requestedID)”")
                    .font(PinwheelTheme.Typography.title)
                    .foregroundStyle(PinwheelTheme.Colors.primaryText)

                Text("Available ids — pass a bare item id, or a qualified sectionID/itemID:")
                    .font(PinwheelTheme.Typography.footnote)
                    .foregroundStyle(PinwheelTheme.Colors.secondaryText)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text(section.title)
                            .font(PinwheelTheme.Typography.subtitleSemibold)
                            .foregroundStyle(PinwheelTheme.Colors.primaryText)

                        ForEach(section.items) { item in
                            Text("\(section.id)/\(item.id)")
                                .font(PinwheelTheme.Typography.caption)
                                .foregroundStyle(PinwheelTheme.Colors.secondaryText)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingL)
        }
        .background(PinwheelTheme.Colors.primaryBackground.ignoresSafeArea())
    }
}
