import SwiftUI
import UIKit
import XCTest
@testable import Pinwheel

@MainActor
enum HostedView {

    static func window(showing view: some SwiftUI.View, style: UIUserInterfaceStyle = .unspecified) -> UIWindow {
        XCTAssertTrue(automationIsOn, "libAccessibility refused the automation switch, so nothing SwiftUI draws is readable.")

        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.overrideUserInterfaceStyle = style
        window.rootViewController = host
        window.isHidden = false
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date())
        host.view.layoutIfNeeded()
        return window
    }

    /// SwiftUI fills its accessibility tree for an attached assistive client, and this switch is what makes
    /// the bundle one.
    private static let automationIsOn: Bool = {
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW), let symbol = dlsym(library, "_AXSSetAutomationEnabled") else {
            return false
        }
        typealias SetAutomationEnabled = @convention(c) (Bool) -> Void
        unsafeBitCast(symbol, to: SetAutomationEnabled.self)(true)
        return true
    }()

    static func accessibilityLabels(in window: UIWindow, ceiling: Int = 2000) -> [String] {
        var labels: [String] = []
        walkAccessibility(in: window, ceiling: ceiling) { object in
            if let label = object.accessibilityLabel, !label.isEmpty { labels.append(label) }
        }
        return labels
    }


    @discardableResult
    static func activateFirst(
        labelled label: String,
        in window: UIWindow,
        ceiling: Int = 2000
    ) -> Bool {
        var activated = false
        walkAccessibility(in: window, ceiling: ceiling) { object in
            guard !activated, object.accessibilityLabel == label else { return }
            activated = object.accessibilityActivate()
        }
        return activated
    }

    /// Traits resolve from the view hierarchy, so a presentation read before it attaches reports
    /// defaults rather than what the window carries.
    static func attachedPresentation(in window: UIWindow) throws -> UIViewController {
        var arrived = false
        for _ in 0..<300 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            guard let presented = window.rootViewController?.presentedViewController else { continue }
            arrived = true
            presented.view.setNeedsLayout()
            presented.view.layoutIfNeeded()
            if presented.view.window != nil { return presented }
        }
        throw PresentationNeverAttached(presented: arrived)
    }


    /// A tray is a child of what it covers rather than a presentation, so waiting for one means waiting
    /// for its card to stand and measure.
    static func attachedTray(in window: UIWindow) throws -> PinTrayChassis {
        for _ in 0..<300 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            window.layoutIfNeeded()
            if let tray = tray(under: window.rootViewController), tray.cardHeight > 0 { return tray }
        }
        throw TrayNeverStood()
    }

    private static func tray(under controller: UIViewController?) -> PinTrayChassis? {
        guard let controller else { return nil }
        if let found = controller as? PinTrayChassis { return found }
        for child in controller.children {
            if let found = tray(under: child) { return found }
        }
        return tray(under: controller.presentedViewController)
    }

    struct TrayNeverStood: Error, CustomStringConvertible {
        var description: String { "No tray stood in the window." }
    }

    private static func walkAccessibility(
        in window: UIWindow,
        ceiling: Int,
        visit: (NSObject) -> Void
    ) {
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))

        var queue: [NSObject] = [window] + presentedViews(from: window.rootViewController)
        var visited = 0

        while let object = queue.first, visited < ceiling {
            queue.removeFirst()
            visited += 1

            visit(object)

            var children = (object.accessibilityElements ?? []).compactMap { $0 as? NSObject }
            if let view = object as? UIView { children += view.subviews }
            queue += children
        }
    }

    private static func presentedViews(from controller: UIViewController?) -> [NSObject] {
        var views: [NSObject] = []
        var presented = controller?.presentedViewController
        while let controller = presented {
            controller.view.layoutIfNeeded()
            views.append(controller.view)
            presented = controller.presentedViewController
        }
        return views
    }

    static func firstSubview<Subview: UIView>(in view: UIView, ofType type: Subview.Type) -> Subview? {
        if let match = view as? Subview { return match }
        for subview in view.subviews {
            if let found = firstSubview(in: subview, ofType: type) { return found }
        }
        return nil
    }
}


struct PresentationNeverAttached: Error, CustomStringConvertible {
    let presented: Bool

    var description: String {
        "The presentation never joined the window. A controller was presented: \(presented)."
    }
}
