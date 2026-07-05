import SwiftUI
import UIKit
import Pinwheel

// Reads SwiftUI's private DisplayList off a hosted view — the exact frames and rendered content
// SwiftUI itself produced, with no anchors or capture markers in the view. All undocumented
// internals (ViewUpdater.lastList, DisplayList item/value shapes, Path.storage, StringDrawing) are
// contained to this file; they shift across toolchains, so a break is one place to fix. Never ships.

struct DisplayLeaf {
    enum Kind {
        case text(String, font: UIFont?, color: UIColor?, underline: Bool)
        case roundedRect(radius: CGFloat, color: UIColor?)
        case rasterizable          // a complex shape (SF Symbol) or platform view — render to a PNG
        case color(UIColor)
        case transparent           // a synthesized group (a fill-less button: label + icon)
        case unknown(String)
    }
    let frame: CGRect
    let kind: Kind
}

@MainActor
enum PinDisplayList {
    // Hosts the view on-screen as a child of the app's key window (a detached/scene-less window never
    // composites, so its pixels are blank) and captures after a runloop so it has actually drawn —
    // the same deferral the crop path always needed. `body` runs while the host is still mounted, then
    // it's torn down.
    static func read<Content: SwiftUI.View>(_ view: Content, size: CGSize, body: @escaping ([DisplayLeaf], [RenderedImage]) -> FigmaDocument?, completion: @escaping (FigmaDocument?) -> Void) {
        // Collect the crisp transparent icon/spinner PNGs that `.pinCapturedRendered` already produces
        // via ImageRenderer (headless, reliable), keyed by their resolved frame — the DisplayList's
        // rasterizable leaves borrow these instead of a fragile screen crop.
        var rendered: [RenderedImage] = []
        let collector = CaptureCollector(content: AnyView(view)) { captured, proxy in
            rendered = captured.compactMap { component in
                component.image.map { RenderedImage(frame: proxy[component.bounds], base64: $0) }
            }
        }
        let controller = UIHostingController(rootView: collector.environment(\.pinCapturing, true))
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        guard let keyWindow = keyWindow(), let rootController = keyWindow.rootViewController else { completion(nil); return }
        rootController.addChild(controller)
        keyWindow.addSubview(controller.view)
        controller.didMove(toParent: rootController)
        controller.view.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            defer {
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
            }
            guard let list = displayList(of: controller.view) else { completion(nil); return }
            completion(body(walk(list, origin: .zero), rendered))
        }
    }

    struct RenderedImage {
        let frame: CGRect
        let base64: String
    }

    private struct CaptureCollector: SwiftUI.View {
        let content: AnyView
        let onCaptured: ([PinCapturedComponent], GeometryProxy) -> Void
        var body: some SwiftUI.View {
            content.backgroundPreferenceValue(PinCaptureKey.self) { captured in
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { onCaptured(captured, proxy) }
                        .onChange(of: captured.count) { onCaptured(captured, proxy) }
                }
            }
        }
    }

    static func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        return windows.first { $0.isKeyWindow } ?? windows.first
    }

    private static func displayList(of hostingView: Any) -> Any? {
        guard let base = child(hostingView, "_base"),
              let graphHost = child(base, "viewGraph"),
              let rendererBox = child(graphHost, "renderer"),
              let updater = unwrap(child(rendererBox, "renderer")) else { return nil }
        return child(updater, "lastList")
    }

    private static func walk(_ list: Any, origin: CGPoint) -> [DisplayLeaf] {
        guard let items = child(list, "items") else { return [] }
        var leaves: [DisplayLeaf] = []
        for item in Mirror(reflecting: items).children.map(\.value) {
            guard let localFrame = child(item, "frame") as? CGRect,
                  let value = child(item, "value"), let (name, payload) = enumCase(value) else { continue }
            let frame = localFrame.offsetBy(dx: origin.x, dy: origin.y)
            if name == "content" {
                let inner = child(payload, "value") ?? payload
                if let kind = contentKind(inner) { leaves.append(DisplayLeaf(frame: frame, kind: kind)) }
            } else {
                let children = nestedLists(in: payload).flatMap { walk($0, origin: frame.origin) }
                // A small, text-free group is an icon or the spinner (rotated capsules that lose their
                // transformed frames) — collapse it to one rasterizable unit at the group's own frame.
                if isRasterUnit(frame, children) {
                    leaves.append(DisplayLeaf(frame: frame, kind: .rasterizable))
                } else {
                    leaves.append(contentsOf: children)
                }
            }
        }
        return leaves
    }

    private static func isRasterUnit(_ frame: CGRect, _ children: [DisplayLeaf]) -> Bool {
        guard frame.width <= 40, frame.height <= 40, !children.isEmpty else { return false }
        return children.allSatisfy { if case .text = $0.kind { return false } else { return true } }
    }

    private static func contentKind(_ value: Any) -> DisplayLeaf.Kind? {
        guard let (kind, payload) = enumCase(value) else { return .unknown(String(describing: type(of: value))) }
        switch kind {
        case "text":
            let attributed = deepAttributed(payload)
            let string = attributed?.string ?? deepString(payload) ?? ""
            let attributes = attributed.flatMap { $0.length > 0 ? $0.attributes(at: 0, effectiveRange: nil) : nil }
            let underline = (attributes?[.underlineStyle] as? Int).map { $0 != 0 } ?? false
            return .text(string, font: attributes?[.font] as? UIFont, color: attributes?[.foregroundColor] as? UIColor, underline: underline)
        case "shape":
            let mirror = Mirror(reflecting: payload).children.map(\.value)
            let color = mirror.count > 1 ? deepColor(mirror[1]) : nil
            if let radius = roundedRectRadius(mirror.first) { return .roundedRect(radius: radius, color: color) }
            return .rasterizable
        case "color": return .color(deepColor(payload) ?? .clear)
        case "platformView": return .rasterizable
        default: return .unknown(kind)
        }
    }

    // SwiftUI Path.storage is an enum; `.roundedRect(FixedRoundedRect)` exposes the exact corner size.
    private static func roundedRectRadius(_ path: Any?) -> CGFloat? {
        guard let path, let storage = child(path, "storage"), let (kind, value) = enumCase(storage) else { return nil }
        if kind == "roundedRect", let size = child(value, "cornerSize") as? CGSize { return size.width }
        if kind == "rect" { return 0 }
        return nil
    }

    private static func nestedLists(in value: Any) -> [Any] {
        var found: [Any] = []
        for level1 in Mirror(reflecting: value).children {
            if isDisplayList(level1.value) { found.append(level1.value) }
            for level2 in Mirror(reflecting: level1.value).children where isDisplayList(level2.value) { found.append(level2.value) }
        }
        return found
    }

    private static func isDisplayList(_ value: Any) -> Bool { String(describing: type(of: value)).contains("DisplayList") }
    private static func child(_ value: Any, _ label: String) -> Any? { Mirror(reflecting: value).children.first { $0.label == label }?.value }
    private static func unwrap(_ value: Any?) -> Any? {
        guard let value else { return nil }
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional ? mirror.children.first?.value : value
    }
    private static func enumCase(_ value: Any) -> (String, Any)? {
        Mirror(reflecting: value).children.first.map { ($0.label ?? "?", $0.value) }
    }
    private static func deepString(_ value: Any, _ depth: Int = 0) -> String? {
        if depth > 6 { return nil }
        if let string = value as? String { return string }
        for child in Mirror(reflecting: value).children { if let found = deepString(child.value, depth + 1) { return found } }
        return nil
    }
    private static func deepAttributed(_ value: Any, _ depth: Int = 0) -> NSAttributedString? {
        if depth > 8 { return nil }
        if let attributed = value as? NSAttributedString { return attributed }
        for child in Mirror(reflecting: value).children { if let found = deepAttributed(child.value, depth + 1) { return found } }
        return nil
    }
    private static func deepColor(_ value: Any, _ depth: Int = 0) -> UIColor? {
        if depth > 8 { return nil }
        if let color = value as? UIColor { return color }
        if CFGetTypeID(value as CFTypeRef) == CGColor.typeID { return UIColor(cgColor: value as! CGColor) }
        // SwiftUI resolves fills to `Color.Resolved` — linear-RGB floats, not a UIColor. Convert.
        if let color = resolvedColor(value) { return color }
        for child in Mirror(reflecting: value).children { if let found = deepColor(child.value, depth + 1) { return found } }
        return nil
    }

    private static func resolvedColor(_ value: Any) -> UIColor? {
        let fields = Dictionary(uniqueKeysWithValues: Mirror(reflecting: value).children.compactMap { child -> (String, Float)? in
            guard let label = child.label, let float = child.value as? Float else { return nil }
            return (label, float)
        })
        guard let red = fields["linearRed"], let green = fields["linearGreen"], let blue = fields["linearBlue"] else { return nil }
        func toSRGB(_ linear: Float) -> CGFloat {
            let value = linear <= 0.0031308 ? linear * 12.92 : 1.055 * pow(linear, 1 / 2.4) - 0.055
            return CGFloat(min(max(value, 0), 1))
        }
        return UIColor(red: toSRGB(red), green: toSRGB(green), blue: toSRGB(blue), alpha: CGFloat(fields["opacity"] ?? 1))
    }
}
