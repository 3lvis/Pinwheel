import UIKit
import SwiftUI

public enum TabletDisplayMode {
    case master
    case detail
    case fullscreen
}

/// How a catalog item is presented when opened.
public enum PinwheelPresentation {
    case medium
    case large
    case fullscreen
}

public typealias PresentationStyle = PinwheelPresentation

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
    public let id: String
    public let title: String
    public let items: [PinwheelItem]

    public init(title: String, id: String? = nil, items: [PinwheelItem]) {
        self.id = id ?? title.pinwheelGeneratedID
        self.title = title
        self.items = items
    }

    public init(_ title: String, id: String? = nil, @PinwheelItemBuilder items: () -> [PinwheelItem]) {
        self.id = id ?? title.pinwheelGeneratedID
        self.title = title
        self.items = items()
    }

    func capitalizedTitles() -> [String] {
        return items.map { $0.title.capitalizingFirstLetter }
    }
}

extension PinwheelSection: Identifiable {}

public struct PinwheelItem {
    public let id: String
    public let title: String
    public let presentation: PinwheelPresentation
    public let supportedInterfaceOrientations: UIInterfaceOrientationMask
    public let constrainToTopSafeArea: Bool
    public let constrainToBottomSafeArea: Bool
    public let tabletDisplayMode: TabletDisplayMode
    private let makeSwiftUIView: () -> AnyView

    func swiftUIView() -> AnyView {
        return makeSwiftUIView()
    }

    private init(
        id: String,
        title: String,
        presentation: PinwheelPresentation,
        supportedInterfaceOrientations: UIInterfaceOrientationMask,
        constrainToTopSafeArea: Bool,
        constrainToBottomSafeArea: Bool,
        tabletDisplayMode: TabletDisplayMode,
        makeSwiftUIView: @escaping () -> AnyView
    ) {
        self.id = id
        self.title = title
        self.presentation = presentation
        self.supportedInterfaceOrientations = supportedInterfaceOrientations
        self.constrainToTopSafeArea = constrainToTopSafeArea
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.tabletDisplayMode = tabletDisplayMode
        self.makeSwiftUIView = makeSwiftUIView
    }

    public init(title: String, id: String? = nil, viewController: UIViewController, tabletDisplayMode: TabletDisplayMode = .fullscreen) {
        self.init(
            id: id ?? title.pinwheelGeneratedID,
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: tabletDisplayMode,
            makeSwiftUIView: {
                AnyView(PinwheelUIKitViewController { viewController })
            }
        )
    }

    public init<ViewType: UIView>(
        _ title: String,
        id: String? = nil,
        view: ViewType.Type
    ) {
        // Shared by the `makeSwiftUIView` closure below so the hosted view is
        // created once and reused (see the note at its use site).
        var sharedHostedView: ViewType?
        self.init(
            id: id ?? title.pinwheelGeneratedID,
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeSwiftUIView: {
                // Build the hosted view once and reuse it across playground
                // re-renders. The bridged tweak closures capture this instance,
                // and `PinwheelUIKitViewController` hosts the same one — a fresh
                // `ViewType` per call would leave the tweaks mutating an
                // off-screen instance, so UIKit tweaks appeared to do nothing
                // (the displayed label never changed) under nested presentation.
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
        id: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            id: id ?? title.pinwheelGeneratedID,
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
        id: String? = nil,
        viewController: @escaping () -> UIViewController
    ) {
        self.init(
            id: id ?? title.pinwheelGeneratedID,
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeSwiftUIView: {
                AnyView(PinwheelUIKitViewController(makeViewController: viewController))
            }
        )
    }
}

extension PinwheelItem: Identifiable {}

public extension PinwheelItem {
    @available(*, deprecated, renamed: "presentation")
    var presentationStyle: PinwheelPresentation {
        return presentation
    }

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

    private func with(
        presentation: PinwheelPresentation,
        supportedInterfaceOrientations: UIInterfaceOrientationMask,
        constrainToTopSafeArea: Bool,
        constrainToBottomSafeArea: Bool,
        tabletDisplayMode: TabletDisplayMode
    ) -> PinwheelItem {
        return PinwheelItem(
            id: id,
            title: title,
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode,
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
    var pinwheelGeneratedID: String {
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

        return dashed.isEmpty ? UUID().uuidString : dashed
    }
}

enum PinwheelStateStore {
    private static let selectedSectionIDKey = "Pinwheel.SelectedSectionID"
    private static let selectedItemIDKey = "Pinwheel.SelectedItemID"
    private static let selectedDeviceBySelectionKey = "Pinwheel.SelectedDeviceBySelection"

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
        State.lastSelectedIndexPath = nil
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
