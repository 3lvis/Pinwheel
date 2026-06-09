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

    @SwiftUI.State private var chrome = PinwheelChrome()

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
                selection: PinwheelSelection(sectionID: match.section.id, itemID: match.item.id),
                onClose: {},
                previewMode: true,
                autoApplyTweak: Self.requestedTweak
            )
            .overlay(alignment: .top) {
                PinwheelPreviewCaption(id: match.item.id, variant: Self.requestedTweak)
            }
            .environment(chrome)
            .background(
                PinwheelFloatingControlsHost(
                    chrome: chrome,
                    tweakCount: chrome.tweakCount,
                    fabVisible: chrome.isFloatingControlsVisible
                )
            )
        } else {
            PinwheelPreviewNotFound(requestedID: id, sections: sections)
        }
    }
}

/// A compact label baked into the preview render so a snapshot identifies the
/// component (and active variant) without relying on the file name.
private struct PinwheelPreviewCaption: SwiftUI.View {
    let id: String
    let variant: String?

    var body: some SwiftUI.View {
        PinLabel(variant.map { "\(id) · \($0)" } ?? id).font(.caption).color(.secondary)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXXS)
            .background(
                Capsule().fill(PinwheelTheme.Colors.secondaryBackground)
            )
            .padding(.top, .spacingXS)
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

    /// The tweak/variant to auto-apply on a preview launch, if any — read from
    /// the `-PinwheelPreviewTweak <title>` launch argument or the
    /// `PINWHEEL_PREVIEW_TWEAK` environment variable. Lets tooling deep-link
    /// straight to a variant (e.g. the StateView "Failed" state).
    static var requestedTweak: String? {
        if let argument = UserDefaults.standard.string(forKey: "PinwheelPreviewTweak"),
           !argument.isEmpty {
            return argument
        }

        if let environment = ProcessInfo.processInfo.environment["PINWHEEL_PREVIEW_TWEAK"],
           !environment.isEmpty {
            return environment
        }

        return nil
    }
}

/// Writes the current preview component's tweak titles to the app's Documents
/// directory (one per line) so external tooling — e.g. `Scripts/preview-all.sh`
/// — can enumerate variants without parsing source. Preview-mode only.
enum PinwheelPreviewTweakDump {
    static let fileName = "pinwheel-preview-tweaks.txt"

    static func write(_ titles: [String]) {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let url = directory.appendingPathComponent(fileName)
        try? titles.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
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
                PinLabel("No component with id “\(requestedID)”").font(.title)

                PinLabel("Available ids — pass a bare item id, or a qualified sectionID/itemID:")
                    .font(.footnote).color(.secondary)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel(section.title).font(.subtitleSemibold)

                        ForEach(section.items) { item in
                            PinLabel("\(section.id)/\(item.id)").font(.caption).color(.secondary)
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
