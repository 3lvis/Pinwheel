import SwiftUI
import UIKit
import Pinwheel

// Reads SwiftUI's private, undocumented DisplayList via reflection — the internals shift across
// toolchains, so all of it is contained to this file. Never ships.

struct DisplayLeaf {
    enum Kind {
        case text(String, font: UIFont?, color: UIColor?, underline: Bool, alignment: NSTextAlignment)
        case roundedRect(radius: CGFloat, color: UIColor?)
        case rasterizable
        case color(UIColor)
        case transparent
        case unknown(String)
    }
    let frame: CGRect
    let kind: Kind
    var image: String? = nil
}

@MainActor
enum PinDisplayList {
    // The window is returned so the caller keeps it alive.
    static func read<Content: SwiftUI.View>(_ view: Content, size: CGSize, liveControlsOnScreen: Bool) -> (leaves: [DisplayLeaf], host: UIView, window: UIWindow)? {
        let controller = UIHostingController(rootView: view)
        let hostView: UIView = controller.view
        hostView.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: hostView.frame)
        window.rootViewController = controller
        window.isHidden = false
        guard let leaves = leaves(fromHost: hostView, liveControlsOnScreen: liveControlsOnScreen) else { return nil }
        return (leaves, hostView, window)
    }

    // Heavy UIKit controls populate the DisplayList only once actually rendered, so reading the live
    // on-screen host (not an off-screen copy) is what makes every control reliably present.
    static func leaves(fromHost hostView: UIView, liveControlsOnScreen: Bool) -> [DisplayLeaf]? {
        hostView.layoutIfNeeded()
        guard let list = displayList(of: hostView) else { return nil }
        return fillRasterCrops(walk(list, origin: .zero), host: hostView, liveControlsOnScreen: liveControlsOnScreen)
    }

    // SwiftUI's renderer returns a blank placeholder for platform-backed content (a List cell's
    // icon/toggle/chevron in the UIKit layer tree), so recover its pixels from a host-layer render.
    private static func fillRasterCrops(_ leaves: [DisplayLeaf], host: UIView, liveControlsOnScreen: Bool) -> [DisplayLeaf] {
        let needsCrop = leaves.contains { if case .rasterizable = $0.kind, $0.image == nil { return true }; return false }
        guard needsCrop else { return leaves }
        return autoreleasepool {
        let full = UIGraphicsImageRenderer(bounds: host.bounds).image { context in host.layer.render(in: context.cgContext) }
        guard let cgImage = full.cgImage else { return leaves }
        let scale = full.scale
        // The layer render includes the safe-area inset but DisplayList frames don't, so crop at
        // frame + inset (a UITableView-hosted List sits inside the safe area).
        let inset = host.safeAreaInsets
        // A UIKit control paints its real appearance only on the live screen (off-screen it's a flat
        // blob). Crop the key window only when the caller vouches this component is the on-screen
        // content — otherwise foreign controls (the catalog's) land on these leaves (the v7 corruption).
        let controlCrops = liveControlsOnScreen ? keyWindowControlCrops() : []
        let wideLeaves = leaves.indices
            .filter { if case .rasterizable = leaves[$0].kind, leaves[$0].image == nil, leaves[$0].frame.width > 40 { return true }; return false }
            .sorted { leaves[$0].frame.minY < leaves[$1].frame.minY }
        let controlByLeaf = matchedControlCrops(
            wideLeaves: wideLeaves.map { (index: $0, frame: leaves[$0].frame) },
            crops: controlCrops
        )
        return leaves.enumerated().map { index, leaf in
            guard case .rasterizable = leaf.kind, leaf.image == nil else { return leaf }
            if let crop = controlByLeaf[index] {
                // SwiftUI's DisplayList undersizes a platform view (the date picker captures 16pt
                // narrower than it draws), so size the leaf to the real control bounds, keeping its origin.
                var filled = DisplayLeaf(frame: CGRect(origin: leaf.frame.origin, size: crop.frame.size), kind: leaf.kind)
                filled.image = crop.image
                return filled
            }
            let rect = CGRect(x: (leaf.frame.minX + inset.left) * scale, y: (leaf.frame.minY + inset.top) * scale,
                              width: leaf.frame.width * scale, height: leaf.frame.height * scale)
            guard rect.width >= 1, rect.height >= 1, let crop = cgImage.cropping(to: rect) else { return leaf }
            var filled = leaf
            filled.image = UIImage(cgImage: crop).pngData()?.base64EncodedString()
            return filled
        }
        }
    }

    // Don't recurse into a control — a stepper's ± are inner buttons, not separate controls.
    private static func keyWindowControlCrops() -> [(frame: CGRect, image: String)] {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else { return [] }
        // Settle layout so control frames are final — mid-layout frames sort wrong and misassign crops.
        window.layoutIfNeeded()
        var controls: [UIView] = []
        func scan(_ view: UIView) {
            if view is UISwitch || view is UISegmentedControl || view is UISlider || view is UIStepper
                || view is UIProgressView || view is UIDatePicker || view is UIActivityIndicatorView {
                controls.append(view)
                return
            }
            view.subviews.forEach(scan)
        }
        scan(window)
        guard !controls.isEmpty else { return [] }
        controls.sort { $0.convert($0.bounds, to: window).minY < $1.convert($1.bounds, to: window).minY }
        // `afterScreenUpdates: false` reads the already-painted front buffer; `true` forces render-server
        // commits that accumulate GPU surfaces the sim never reclaims, degrading it into dropping controls.
        return autoreleasepool {
            let full = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: false) }
            guard let cgImage = full.cgImage else { return [] }
            let scale = full.scale
            return controls.compactMap { control in
                let frame = control.convert(control.bounds, to: window)
                let rect = CGRect(x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale, height: frame.height * scale)
                guard let crop = cgImage.cropping(to: rect),
                      let image = UIImage(cgImage: crop).pngData()?.base64EncodedString() else { return nil }
                return (frame: frame, image: image)
            }
        }
    }

    static func matchedControlCrops(
        wideLeaves: [(index: Int, frame: CGRect)],
        crops: [(frame: CGRect, image: String)]
    ) -> [Int: (frame: CGRect, image: String)] {
        guard !wideLeaves.isEmpty, wideLeaves.count == crops.count else { return [:] }
        let leaves = wideLeaves.sorted { $0.frame.minY < $1.frame.minY }
        let sortedCrops = crops.sorted { $0.frame.minY < $1.frame.minY }
        var result: [Int: (frame: CGRect, image: String)] = [:]
        for (leaf, crop) in zip(leaves, sortedCrops) { result[leaf.index] = crop }
        return result
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
                if let (kind, data) = enumCase(inner), kind == "shape",
                   let path = Mirror(reflecting: data).children.first?.value as? SwiftUI.Path, roundedRectRadius(path) == nil {
                    leaves.append(DisplayLeaf(frame: frame, kind: .rasterizable, image: renderPath(path, color: deepColor(data), unitSize: frame.size)))
                } else if let kind = contentKind(inner) {
                    leaves.append(DisplayLeaf(frame: frame, kind: kind))
                }
            } else {
                var children = nestedLists(in: payload).flatMap { walk($0, origin: frame.origin) }
                // A clipShape(RoundedRectangle) rides a separate clip effect, not the fill, so round the
                // fill it wraps by the clip's corner radius.
                if let radius = clipCornerRadius(payload) {
                    children = children.map { rounded($0, by: radius, matching: frame) }
                }
                if isRasterUnit(frame, children) {
                    leaves.append(DisplayLeaf(frame: frame, kind: .rasterizable, image: renderShapes(in: payload, unitSize: frame.size)))
                } else if isBareButton(frame, children) {
                    leaves.append(DisplayLeaf(frame: frame, kind: .transparent))
                    leaves.append(contentsOf: children)
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

    // A clipShape's FixedRoundedRect lives in the effect payload, not the nested content — search the
    // payload without descending into child display lists.
    private static func clipCornerRadius(_ payload: Any, _ depth: Int = 0) -> CGFloat? {
        if depth > 8 { return nil }
        if String(describing: type(of: payload)).contains("FixedRoundedRect"), let size = child(payload, "cornerSize") as? CGSize {
            return size.width
        }
        for field in Mirror(reflecting: payload).children where !isDisplayList(field.value) {
            if let radius = clipCornerRadius(field.value, depth + 1) { return radius }
        }
        return nil
    }

    private static func rounded(_ leaf: DisplayLeaf, by radius: CGFloat, matching frame: CGRect) -> DisplayLeaf {
        guard abs(leaf.frame.width - frame.width) < 2, abs(leaf.frame.height - frame.height) < 2 else { return leaf }
        switch leaf.kind {
        case .color(let color): return DisplayLeaf(frame: leaf.frame, kind: .roundedRect(radius: radius, color: color))
        case .roundedRect(_, let color): return DisplayLeaf(frame: leaf.frame, kind: .roundedRect(radius: radius, color: color))
        default: return leaf
        }
    }

    private static func isBareButton(_ frame: CGRect, _ children: [DisplayLeaf]) -> Bool {
        guard frame.height >= 30, !children.isEmpty else { return false }
        var textCount = 0
        for child in children {
            switch child.kind {
            case .text: textCount += 1
            case .rasterizable: break
            default: return false
            }
        }
        guard textCount == 1 else { return false }
        // SwiftUI pads a button's box around its label (or hits the control min-width) but a multi-line
        // label fills its frame edge to edge — only the padded case is a button.
        let content = children.map(\.frame).reduce(children[0].frame) { $0.union($1) }
        return (frame.width - content.width) / 2 > 4
    }

    private static func renderPath(_ path: SwiftUI.Path, color: UIColor?, unitSize: CGSize) -> String? {
        let bounds = path.boundingRect
        let size = CGSize(width: max(unitSize.width, 1), height: max(unitSize.height, 1))
        let image = UIGraphicsImageRenderer(size: size).image { context in
            context.cgContext.translateBy(x: -bounds.minX, y: -bounds.minY)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.setFillColor((color ?? .label).cgColor)
            context.cgContext.fillPath()
        }
        return image.pngData()?.base64EncodedString()
    }

    private static func renderShapes(in effectPayload: Any, unitSize: CGSize) -> String? {
        var shapes: [(path: SwiftUI.Path, color: UIColor?, origin: CGPoint)] = []
        func collect(_ payload: Any, _ origin: CGPoint) {
            for nested in nestedLists(in: payload) {
                guard let items = child(nested, "items") else { continue }
                for item in Mirror(reflecting: items).children.map(\.value) {
                    guard let localFrame = child(item, "frame") as? CGRect,
                          let value = child(item, "value"), let (name, payload) = enumCase(value) else { continue }
                    let childOrigin = CGPoint(x: origin.x + localFrame.minX, y: origin.y + localFrame.minY)
                    if name == "content" {
                        let inner = child(payload, "value") ?? payload
                        if let (kind, data) = enumCase(inner), kind == "shape",
                           let path = Mirror(reflecting: data).children.first?.value as? SwiftUI.Path {
                            shapes.append((path, deepColor(data), childOrigin))
                        }
                    } else {
                        collect(payload, childOrigin)
                    }
                }
            }
        }
        collect(effectPayload, .zero)
        guard !shapes.isEmpty else { return nil }
        let size = CGSize(width: max(unitSize.width, 1), height: max(unitSize.height, 1))
        let image = UIGraphicsImageRenderer(size: size).image { context in
            for shape in shapes {
                let bounds = shape.path.boundingRect
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: shape.origin.x - bounds.minX, y: shape.origin.y - bounds.minY)
                context.cgContext.addPath(shape.path.cgPath)
                context.cgContext.setFillColor((shape.color ?? .label).cgColor)
                context.cgContext.fillPath()
                context.cgContext.restoreGState()
            }
        }
        return image.pngData()?.base64EncodedString()
    }

    private static func contentKind(_ value: Any) -> DisplayLeaf.Kind? {
        guard let (kind, payload) = enumCase(value) else { return .unknown(String(describing: type(of: value))) }
        switch kind {
        case "text":
            let attributed = deepAttributed(payload)
            let string = attributed?.string ?? deepString(payload) ?? ""
            let attributes = attributed.flatMap { $0.length > 0 ? $0.attributes(at: 0, effectiveRange: nil) : nil }
            let underline = (attributes?[.underlineStyle] as? Int).map { $0 != 0 } ?? false
            let alignment = (attributes?[.paragraphStyle] as? NSParagraphStyle)?.alignment ?? .natural
            return .text(string, font: attributes?[.font] as? UIFont, color: attributes?[.foregroundColor] as? UIColor, underline: underline, alignment: alignment)
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
        // SwiftUI resolves fills to `Color.Resolved` — linear-RGB floats, not a UIColor.
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
