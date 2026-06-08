import UIKit
import SwiftUI

public enum TabletDisplayMode {
    case master
    case detail
    case fullscreen
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
    private let makeViewController: (PinwheelPresentation, UIInterfaceOrientationMask, Bool, Bool) -> UIViewController
    private let makeSwiftUIView: () -> AnyView

    public var viewController: UIViewController {
        return makeViewController(
            presentation,
            supportedInterfaceOrientations,
            constrainToTopSafeArea,
            constrainToBottomSafeArea
        )
    }

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
        makeViewController: @escaping (PinwheelPresentation, UIInterfaceOrientationMask, Bool, Bool) -> UIViewController,
        makeSwiftUIView: @escaping () -> AnyView
    ) {
        self.id = id
        self.title = title
        self.presentation = presentation
        self.supportedInterfaceOrientations = supportedInterfaceOrientations
        self.constrainToTopSafeArea = constrainToTopSafeArea
        self.constrainToBottomSafeArea = constrainToBottomSafeArea
        self.tabletDisplayMode = tabletDisplayMode
        self.makeViewController = makeViewController
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
            makeViewController: { presentation, _, _, _ in
                viewController.configurePinwheelPresentationStyle(presentation)
                return viewController
            },
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
        self.init(
            id: id ?? title.pinwheelGeneratedID,
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainToTopSafeArea: true,
            constrainToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            makeViewController: { presentation, orientations, constrainToTopSafeArea, constrainToBottomSafeArea in
                PinwheelViewController<ViewType>(
                    presentationStyle: presentation,
                    supportedInterfaceOrientations: orientations,
                    constrainToTopSafeArea: constrainToTopSafeArea,
                    constrainToBottomSafeArea: constrainToBottomSafeArea
                )
            },
            makeSwiftUIView: {
                let view = ViewType(frame: .zero)
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
            makeViewController: { presentation, orientations, constrainToTopSafeArea, constrainToBottomSafeArea in
                PinwheelHostingViewController(
                    rootView: content(),
                    presentationStyle: presentation,
                    supportedInterfaceOrientations: orientations,
                    constrainToTopSafeArea: constrainToTopSafeArea,
                    constrainToBottomSafeArea: constrainToBottomSafeArea
                )
            },
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
            makeViewController: { presentation, _, _, _ in
                let controller = viewController()
                controller.configurePinwheelPresentationStyle(presentation)
                return controller
            },
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

    func pinwheelPresentation(_ presentation: PinwheelPresentation) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func pinwheelSupportedInterfaceOrientations(_ orientations: UIInterfaceOrientationMask) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: orientations,
            constrainToTopSafeArea: constrainToTopSafeArea,
            constrainToBottomSafeArea: constrainToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func pinwheelSafeArea(top: Bool = true, bottom: Bool = true) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainToTopSafeArea: top,
            constrainToBottomSafeArea: bottom,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func pinwheelTabletDisplayMode(_ mode: TabletDisplayMode) -> PinwheelItem {
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
            makeViewController: makeViewController,
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

extension UIViewController {
    func configurePinwheelPresentationStyle(_ presentationStyle: PresentationStyle) {
        if #available(iOS 15.0, *) {
            switch presentationStyle {
            case .medium:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.medium()]
                sheetPresentationController?.preferredCornerRadius = .spacingXL
                sheetPresentationController?.prefersGrabberVisible = true
            case .large:
                modalPresentationStyle = .pageSheet
                sheetPresentationController?.detents = [.large()]
                sheetPresentationController?.preferredCornerRadius = .spacingXL
                sheetPresentationController?.prefersGrabberVisible = true
            case .fullscreen:
                modalPresentationStyle = .fullScreen
            }
        } else if presentationStyle == .fullscreen {
            modalPresentationStyle = .fullScreen
        }
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
