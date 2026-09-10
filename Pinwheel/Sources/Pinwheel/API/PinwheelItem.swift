import UIKit
import SwiftUI

@resultBuilder
public enum PinwheelItemBuilder {
    public static func buildExpression(_ expression: PinwheelItem) -> [PinwheelItem] {
        return [expression]
    }

    public static func buildExpression(_ expression: [PinwheelItem]) -> [PinwheelItem] {
        return expression
    }

    public static func buildBlock(_ components: [PinwheelItem]...) -> [PinwheelItem] {
        return components.flatMap { $0 }
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

public struct PinwheelItem {
    public let title: String
    public let presentation: PinwheelPresentation
    public let supportedInterfaceOrientations: UIInterfaceOrientationMask
    public let constrainsToTopSafeArea: Bool
    public let constrainsToBottomSafeArea: Bool
    public let tabletDisplayMode: PinwheelTabletDisplayMode
    public let tags: [PinTag]
    public let isUIKitHosted: Bool
    private let makeSwiftUIView: () -> AnyView

    /// Slugified title prefixed by tags, so same-titled items in different worlds
    /// (SwiftUI "Font" vs UIKit "Font") get distinct ids. Title + tags must be
    /// unique within a section.
    public var id: String {
        PinwheelItem.generatedID(title: title, tags: tags)
    }

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
        constrainsToTopSafeArea: Bool,
        constrainsToBottomSafeArea: Bool,
        tabletDisplayMode: PinwheelTabletDisplayMode,
        tags: [PinTag] = [],
        isUIKitHosted: Bool,
        makeSwiftUIView: @escaping () -> AnyView
    ) {
        self.title = title
        self.presentation = presentation
        self.supportedInterfaceOrientations = supportedInterfaceOrientations
        self.constrainsToTopSafeArea = constrainsToTopSafeArea
        self.constrainsToBottomSafeArea = constrainsToBottomSafeArea
        self.tabletDisplayMode = tabletDisplayMode
        self.tags = tags
        self.isUIKitHosted = isUIKitHosted
        self.makeSwiftUIView = makeSwiftUIView
    }

    public init(title: String, viewController: UIViewController, tabletDisplayMode: PinwheelTabletDisplayMode = .fullscreen) {
        self.init(
            title: title,
            presentation: .fullscreen,
            supportedInterfaceOrientations: .all,
            constrainsToTopSafeArea: true,
            constrainsToBottomSafeArea: true,
            tabletDisplayMode: tabletDisplayMode,
            isUIKitHosted: true,
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
            constrainsToTopSafeArea: true,
            constrainsToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            isUIKitHosted: true,
            makeSwiftUIView: {
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
            constrainsToTopSafeArea: true,
            constrainsToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            isUIKitHosted: false,
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
            constrainsToTopSafeArea: true,
            constrainsToBottomSafeArea: true,
            tabletDisplayMode: .fullscreen,
            isUIKitHosted: true,
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
            constrainsToTopSafeArea: constrainsToTopSafeArea,
            constrainsToBottomSafeArea: constrainsToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func supportedInterfaceOrientations(_ orientations: UIInterfaceOrientationMask) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: orientations,
            constrainsToTopSafeArea: constrainsToTopSafeArea,
            constrainsToBottomSafeArea: constrainsToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func safeArea(top: Bool = true, bottom: Bool = true) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainsToTopSafeArea: top,
            constrainsToBottomSafeArea: bottom,
            tabletDisplayMode: tabletDisplayMode
        )
    }

    func tabletDisplayMode(_ mode: PinwheelTabletDisplayMode) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainsToTopSafeArea: constrainsToTopSafeArea,
            constrainsToBottomSafeArea: constrainsToBottomSafeArea,
            tabletDisplayMode: mode
        )
    }

    func tags(_ tags: PinTag...) -> PinwheelItem {
        return with(
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainsToTopSafeArea: constrainsToTopSafeArea,
            constrainsToBottomSafeArea: constrainsToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode,
            tags: tags
        )
    }

    private func with(
        presentation: PinwheelPresentation,
        supportedInterfaceOrientations: UIInterfaceOrientationMask,
        constrainsToTopSafeArea: Bool,
        constrainsToBottomSafeArea: Bool,
        tabletDisplayMode: PinwheelTabletDisplayMode,
        tags: [PinTag]? = nil
    ) -> PinwheelItem {
        return PinwheelItem(
            title: title,
            presentation: presentation,
            supportedInterfaceOrientations: supportedInterfaceOrientations,
            constrainsToTopSafeArea: constrainsToTopSafeArea,
            constrainsToBottomSafeArea: constrainsToBottomSafeArea,
            tabletDisplayMode: tabletDisplayMode,
            tags: tags ?? self.tags,
            isUIKitHosted: isUIKitHosted,
            makeSwiftUIView: makeSwiftUIView
        )
    }
}
