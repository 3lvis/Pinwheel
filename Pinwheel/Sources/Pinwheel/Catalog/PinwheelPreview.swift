import Foundation
import SwiftUI

/// Renders one catalog component by id. `id` is a bare item id (`"button"`) or a
/// qualified `"sectionID/itemID"` to disambiguate items that share an id.
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
        if let match = Self.resolve(id: id, in: sections) {
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

private struct PinwheelPreviewCaption: SwiftUI.View {
    let id: String
    let variant: String?

    var body: some SwiftUI.View {
        PinLabel(variant.map { "\(id) · \($0)" } ?? id).font(.caption).color(.secondary)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXXS)
            .background(
                Capsule().fill(.secondaryBackground)
            )
            .padding(.top, .spacingXS)
    }
}

public extension PinwheelPreview {
    /// The component id for an isolated preview launch: the `-PinwheelPreview <id>`
    /// launch argument or the `PINWHEEL_PREVIEW` env var, else nil.
    static var requestedID: String? {
        // `-key value` launch args are surfaced as UserDefaults values.
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

    /// The tweak/variant to auto-apply on a preview launch: the
    /// `-PinwheelPreviewTweak <title>` launch argument or `PINWHEEL_PREVIEW_TWEAK`, else nil.
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
        .background(.primaryBackground)
    }
}
