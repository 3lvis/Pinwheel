import UIKit
import SwiftUI

public enum TabletDisplayMode {
    case master
    case detail
    case fullscreen
}

public enum PinwheelPresentation {
    case medium
    case large
    case fullscreen
}

/// A filter axis on a concept-grouped item (e.g. SwiftUI/UIKit), not its own section; consumers add axes via a static extension.
public struct PinTag: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public nonisolated init(rawValue: String) { self.rawValue = rawValue }
}

public extension PinTag {
    nonisolated static let swiftUI = PinTag(rawValue: "SwiftUI")
    nonisolated static let uiKit = PinTag(rawValue: "UIKit")
}

@resultBuilder
public enum PinwheelSectionBuilder {
    public static func buildBlock(_ components: PinwheelSection...) -> [PinwheelSection] {
        return components
    }

    public static func buildArray(_ components: [[PinwheelSection]]) -> [PinwheelSection] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [PinwheelSection]?) -> [PinwheelSection] {
        return component ?? []
    }

    public static func buildEither(first component: [PinwheelSection]) -> [PinwheelSection] {
        return component
    }

    public static func buildEither(second component: [PinwheelSection]) -> [PinwheelSection] {
        return component
    }
}

@resultBuilder
public enum PinwheelItemBuilder {
    public static func buildBlock(_ components: PinwheelItem...) -> [PinwheelItem] {
        return components
    }

    public static func buildArray(_ components: [[PinwheelItem]]) -> [PinwheelItem] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [PinwheelItem]?) -> [PinwheelItem] {
        return component ?? []
    }

    public static func buildEither(first component: [PinwheelItem]) -> [PinwheelItem] {
        return component
    }

    public static func buildEither(second component: [PinwheelItem]) -> [PinwheelItem] {
        return component
    }
}

public struct PinwheelSection {
    public let title: String
    public let items: [PinwheelItem]

    /// Slugified title; must be unique within a catalog since persistence keys off it.
    public var id: String {
        title.pinwheelGeneratedID
    }

    public init(title: String, items: [PinwheelItem]) {
        self.title = title
        self.items = items
    }

    public init(_ title: String, @PinwheelItemBuilder items: () -> [PinwheelItem]) {
        self.title = title
        self.items = items()
    }
}

extension PinwheelSection: Identifiable {}

public struct PinwheelItem {
    public let title: String
    public let presentation: PinwheelPresentation
    public let supportedInterfaceOrientations: UIInterfaceOrientationMask
    public let constrainToTopSafeArea: Bool
    public let constrainToBottomSafeArea: Bool
    public let tabletDisplayMode: TabletDisplayMode
    public let tags: [PinTag]
    private let makeSwiftUIView: () -> AnyView

    /// Slugified title prefixed by tags, so same-titled items in different worlds
    /// (SwiftUI "Font" vs UIKit "Font") get distinct ids. Title + tags must be
    /// unique within a section.
    public var id: String {
        PinwheelItem.generatedID(title: title, tags: tags)
    }

    /// Lets callers form a deep-link (`-PinwheelPreview <id>`) without hardcoding the slug.
    nonisolated public static func generatedID(title: String, tags: [PinTag] = []) -> String {
        return (tags.map(\.rawValue) + [title]).joined(separator: " ").pinwheelGeneratedID
    }

    public func swiftUIView() -> AnyView {
        return makeSwiftUIView()
    }

    private init(
        title: String,
        presentation: PinwheelPresentation,
        supportedInterfaceOrientations: UIInterfaceOrientationMask,
        constrainToTopSafeArea: Bool,
        constrainToBottomSafeArea: Bool,
        tabletDisplayMode: TabletDisplayMode,
        tags: [PinTag] = [],
        makeSwiftUIView: @escaping () -> AnyView
    ) {
        self.title = title
        self.presentation = presentation
        self.supportedInterfaceOrientations = supportedInterfaceOrientations
        self.constrainToTopSafeArea = constrainToTopSafeArea
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.tabletDisplayMode = tabletDisplayMode
        self.tags = tags
        self.makeSwiftUIView = makeSwiftUIView
    }

    public init(title: String, viewController: UIViewController, tabletDisplayMode: TabletDisplayMode = .fullscreen) {
        self.init(
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: tabletDisplayMode,
            makeSwiftUIView: {
                let tweaks = (viewController as? Tweakable)?.tweaks.compactMap { PinwheelTweak($0) } ?? []
                return AnyView(
                    PinwheelUIKitViewController { viewController }
                        .pinwheelTweaks(tweaks)
                )
            }
        )
    }

    public init<ViewType: UIView>(
        _ title: String,
        view: ViewType.Type
    ) {
        var sharedHostedView: ViewType?
        self.init(
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeSwiftUIView: {
                // Reuse the same view across renders. The tweak controls hold onto it, so a
                // fresh one each render would leave them driving a hidden, discarded copy.
                let view = sharedHostedView ?? {
                    let created = ViewType(frame: .zero)
                    sharedHostedView = created
                    return created
                }()
                let tweaks = (view as? Tweakable)?.tweaks.compactMap { PinwheelTweak($0) } ?? []
                return AnyView(
                    PinwheelUIKitViewController {
                        PinwheelUIKitContainerViewController { view }
                    }
                    .pinwheelTweaks(tweaks)
                )
            }
        )
    }

    public init<Content: SwiftUI.View>(
        _ title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeSwiftUIView: {
                AnyView(content())
            }
        )
    }

    public init(
        _ title: String,
        viewController: @escaping () -> UIViewController
    ) {
        // Reuse the same controller across renders. The tweak controls hold onto it, so a
        // fresh one each render would leave them driving a hidden, discarded copy.
        var sharedViewController: UIViewController?
        self.init(
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeSwiftUIView: {
                let controller = sharedViewController ?? {
                    let created = viewController()
                    sharedViewController = created
                    return created
                }()
                let tweaks = (controller as? Tweakable)?.tweaks.compactMap { PinwheelTweak($0) } ?? []
                return AnyView(
                    PinwheelUIKitViewController { controller }
                        .pinwheelTweaks(tweaks)
                )
            }
        )
    }
}

extension PinwheelItem: Identifiable {}

public extension PinwheelItem {
    func presentation(_ presentation: PinwheelPresentation) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func supportedInterfaceOrientations(_ orientations: UIInterfaceOrientationMask) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: orientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func safeArea(top: Bool = true, bottom: Bool = true) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: top,
            constrainToBottomSafeArea: bottom,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func tabletDisplayMode(_ mode: TabletDisplayMode) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: mode
        )
    }

    func tags(_ tags: PinTag...) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode,
            tags: tags
        )
    }

    private func with(
        presentation: PinwheelPresentation,
        supportedInterfaceOrientations: UIInterfaceOrientationMask,
        constrainToTopSafeArea: Bool,
        constrainToBottomSafeArea: Bool,
        tabletDisplayMode: TabletDisplayMode,
        tags: [PinTag]? = nil
    ) -> PinwheelItem {
        return PinwheelItem(
            title: title,
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode,
            tags: tags ?? self.tags,
            makeSwiftUIView: makeSwiftUIView
        )
    }
}

public struct PinwheelSelection: Hashable, Identifiable {
    public let sectionID: String
    public let itemID: String

    public var id: String {
        return "\(sectionID)/\(itemID)"
    }

    public init(sectionID: String, itemID: String) {
        self.sectionID = sectionID
        self.itemID = itemID
    }
}

public struct PinwheelCatalog: SwiftUI.View {
    private let sections: [PinwheelSection]
    private let usesEmbeddedNavigation: Bool

    public init(usesEmbeddedNavigation: Bool = true, @PinwheelSectionBuilder sections: () -> [PinwheelSection]) {
        self.sections = sections()
        self.usesEmbeddedNavigation = usesEmbeddedNavigation
    }

    public var body: some SwiftUI.View {
        PinwheelCatalogView(sections: sections, usesEmbeddedNavigation: usesEmbeddedNavigation)
    }
}

private extension String {
    nonisolated var pinwheelGeneratedID: String {
        let allowed = CharacterSet.alphanumerics
        let scalars = unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(String(scalar).lowercased())
            } else {
                return "-"
            }
        }

        let dashed = String(scalars)
            .split(separator: "-")
            .joined(separator: "-")

        if !dashed.isEmpty { return dashed }
        // `id` is computed, so a random fallback would re-roll on every read and
        // break persistence/deep-links. Derive a deterministic id from the scalar
        // code points for titles that slugify to empty (emoji/punctuation-only).
        let hex = unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: "-")
        return hex.isEmpty ? "untitled" : hex
    }
}

enum PinwheelStateStore {
    private static let selectedSectionIDKey = "Pinwheel.SelectedSectionID"
    private static let selectedItemIDKey = "Pinwheel.SelectedItemID"
    private static let selectedDeviceBySelectionKey = "Pinwheel.SelectedDeviceBySelection"
    // Legacy key retained so the persisted FAB corner survives.
    private static let floatingControlsCornerKey = "lastCornerForTweakingButtonKey"

    static var selectedSectionID: String? {
        get { UserDefaults.standard.string(forKey: selectedSectionIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedSectionIDKey) }
    }

    static var selectedItemID: String? {
        get { UserDefaults.standard.string(forKey: selectedItemIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedItemIDKey) }
    }

    static func clearSelectedItem() {
        UserDefaults.standard.removeObject(forKey: selectedItemIDKey)
    }

    static var floatingControlsCorner: Int? {
        get { UserDefaults.standard.object(forKey: floatingControlsCornerKey) as? Int }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: floatingControlsCornerKey)
            } else {
                UserDefaults.standard.removeObject(forKey: floatingControlsCornerKey)
            }
        }
    }

    static func selectedDeviceIndex(for selection: PinwheelSelection) -> Int? {
        let values = UserDefaults.standard.dictionary(forKey: selectedDeviceBySelectionKey) as? [String: Int]
        return values?[selection.id]
    }

    static func setSelectedDeviceIndex(_ deviceIndex: Int?, for selection: PinwheelSelection) {
        var values = UserDefaults.standard.dictionary(forKey: selectedDeviceBySelectionKey) as? [String: Int] ?? [:]
        values[selection.id] = deviceIndex
        UserDefaults.standard.set(values, forKey: selectedDeviceBySelectionKey)
    }
}
