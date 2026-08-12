import SwiftUI
import UIKit
import XCTest

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

    /// Where the elements carrying `label` were laid out, in the window's own coordinates, since
    /// `accessibilityFrame` reports the screen's.
    static func accessibilityFrames(
        in window: UIWindow,
        labelled label: String,
        ceiling: Int = 2000
    ) -> [CGRect] {
        var frames: [CGRect] = []
        walkAccessibility(in: window, ceiling: ceiling) { object in
            if object.accessibilityLabel == label { frames.append(window.convert(object.accessibilityFrame, from: nil)) }
        }
        return frames
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

    /// The presented controller, once its view has joined the window — traits resolve from the
    /// hierarchy, so one read before the presentation is attached reports the defaults instead.
    static func presentation(in window: UIWindow) throws -> UIViewController {
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

    /// The presentation a sheet settled on, once the height it measured for itself stops moving — a
    /// measured detent is applied a beat after the sheet appears.
    static func settledPresentation(in window: UIWindow) throws -> UIViewController {
        var heights: [CGFloat] = []
        var presentation: UIViewController?

        for _ in 0..<300 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
            guard let presented = window.rootViewController?.presentedViewController else { continue }
            presentation = presented
            presented.view.layoutIfNeeded()
            heights.append(presented.view.frame.height)
            if heights.count >= 5, Set(heights.suffix(5)).count == 1, heights.last ?? 0 > 0 {
                return presented
            }
        }

        throw SheetNeverSettled(presented: presentation != nil, heights: Array(heights.suffix(10)))
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

struct SheetNeverSettled: Error, CustomStringConvertible {
    let presented: Bool
    let heights: [CGFloat]

    var description: String {
        "The sheet settled on no height. Presented: \(presented). Heights seen: \(heights)."
    }
}

struct PresentationNeverAttached: Error, CustomStringConvertible {
    let presented: Bool

    var description: String {
        "The presentation never joined the window. A controller was presented: \(presented)."
    }
}
