import SwiftUI
import UIKit
import Pinwheel

// Reads SwiftUI's private DisplayList off a hosted view — the exact frames and rendered content
// SwiftUI itself produced, with no anchors or capture markers in the view. All undocumented
// internals (ViewUpdater.lastList, DisplayList item/value shapes, Path.storage, StringDrawing) are
// contained to this file; they shift across toolchains, so a break is one place to fix. Never ships.

struct DisplayLeaf {
    enum Kind {
        case text(String, font: UIFont?, color: UIColor?, underline: Bool, alignment: NSTextAlignment)
        case roundedRect(radius: CGFloat, color: UIColor?)
        case rasterizable          // a complex shape (SF Symbol) or platform view — render to a PNG
        case color(UIColor)
        case transparent           // a synthesized group (a fill-less button: label + icon)
        case unknown(String)
    }
    let frame: CGRect
    let kind: Kind
    // A pre-rendered PNG for a rasterizable unit — the symbol/spinner shapes drawn headless via
    // CoreGraphics (the DisplayList hands us the vector Path, so no screen crop is needed).
    var image: String? = nil
}

@MainActor
enum PinDisplayList {
    // Reads the rendered DisplayList off a hosted copy. Synchronous — the display list is populated by
    // layoutIfNeeded, and it captures every demo reliably (the async on-screen variant only existed for
    // an icon crop that never worked). The window is returned so the caller keeps it alive.
    static func read<Content: SwiftUI.View>(_ view: Content, size: CGSize, liveControlsOnScreen: Bool) -> (leaves: [DisplayLeaf], host: UIView, window: UIWindow)? {
        let controller = UIHostingController(rootView: view.environment(\.pinCapturing, true))
        let hostView: UIView = controller.view
        hostView.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: hostView.frame)
        window.rootViewController = controller
        window.isHidden = false
        hostView.layoutIfNeeded()
        guard let list = displayList(of: hostView) else { return nil }
        return (fillRasterCrops(walk(list, origin: .zero), host: hostView, liveControlsOnScreen: liveControlsOnScreen), hostView, window)
    }

    // A rasterizable leaf the DisplayList gave us no vector Path for — a UITableView-hosted List cell's
    // icon/toggle/chevron lives in the UIKit layer tree, and SwiftUI's renderer returns a blank
    // placeholder for platform-backed content. Recover its pixels by rendering the host layer once and
    // cropping each blank region (the UIKit-layer render captures what SwiftUI's renderer can't).
    private static func fillRasterCrops(_ leaves: [DisplayLeaf], host: UIView, liveControlsOnScreen: Bool) -> [DisplayLeaf] {
        let needsCrop = leaves.contains { if case .rasterizable = $0.kind, $0.image == nil { return true }; return false }
        guard needsCrop else { return leaves }
        let full = UIGraphicsImageRenderer(bounds: host.bounds).image { context in host.layer.render(in: context.cgContext) }
        guard let cgImage = full.cgImage else { return leaves }
        let scale = full.scale
        // The layer render includes the safe-area inset; the DisplayList frames are relative to the
        // content below it. Read the crop from frame + inset so the icon lands on its own row, not the
        // empty strip above (a UITableView-hosted List sits inside the safe area).
        let inset = host.safeAreaInsets
        // A UIKit control (switch, segmented, slider, stepper, progress, date picker) paints its real
        // appearance/state only on the live screen (off-screen it's a flat blob), so crop those from the
        // on-screen key window and assign them to the wide rasterizable leaves in vertical order;
        // icons/chevrons crop the off-screen host fine. Only crop the key window when the caller vouches
        // that this component *is* the on-screen content — otherwise the key window is some other surface
        // (the catalog) and its controls would land on this component's leaves (the v7 corruption).
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
                // Size the leaf to the real control bounds. SwiftUI's DisplayList undersizes a platform
                // view (the date picker captures 16pt narrower than it draws), so keeping the placeholder
                // frame would crop the live crop under the plugin's FILL. Keep the laid-out origin.
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

    // Real control pixels: find each top-level UIKit control in the on-screen key window and crop it from
    // a live-window render (drawHierarchy paints the actual control — state, knob, tint — that an
    // off-screen render can't). Don't recurse into a control (a stepper's ± are inner buttons).
    private static func keyWindowControlCrops() -> [(frame: CGRect, image: String)] {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else { return [] }
        // Settle layout so control frames are final — mid-layout frames sort wrong and misassign crops.
        window.layoutIfNeeded()
        var controls: [UIView] = []
        func scan(_ view: UIView) {
            if view is UISwitch || view is UISegmentedControl || view is UISlider || view is UIStepper
                || view is UIProgressView || view is UIDatePicker {
                controls.append(view)
                return
            }
            view.subviews.forEach(scan)
        }
        scan(window)
        guard !controls.isEmpty else { return [] }
        controls.sort { $0.convert($0.bounds, to: window).minY < $1.convert($1.bounds, to: window).minY }
        let full = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
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

    // Assign the live control crops to the wide rasterizable leaves by vertical order. The caller only
    // passes live crops when the component is the on-screen content (the sweep), so the on-screen
    // controls top-to-bottom are this component's controls top-to-bottom — no geometric matching needed,
    // which is why this survives a UITableView whose off-screen and on-screen row spacing differ. The
    // returned crop carries its frame so the leaf can size to the real control bounds. When the component
    // isn't on screen (the catalog), the caller passes no crops, so nothing foreign is ever assigned —
    // that's what prevents the v7 corruption (see Tests/PinwheelTests/Fixtures/apple-controls-v7-corruption.png).
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
                    // A complex (non rounded-rect) shape — an SF Symbol or the single-path spinner —
                    // render its vector headless rather than leaving it a blank rasterizable.
                    leaves.append(DisplayLeaf(frame: frame, kind: .rasterizable, image: renderPath(path, color: deepColor(data), unitSize: frame.size)))
                } else if let kind = contentKind(inner) {
                    leaves.append(DisplayLeaf(frame: frame, kind: kind))
                }
            } else {
                var children = nestedLists(in: payload).flatMap { walk($0, origin: frame.origin) }
                // A clipShape(RoundedRectangle) rides a clip effect, not the fill — round the fill it
                // wraps (a card's background) by its corner radius so the corners match.
                if let radius = clipCornerRadius(payload) {
                    children = children.map { rounded($0, by: radius, matching: frame) }
                }
                // A small, text-free group is an icon or the spinner — render its vector shapes headless
                // into one rasterizable unit (the DisplayList gives us the Path, so no screen crop).
                if isRasterUnit(frame, children) {
                    leaves.append(DisplayLeaf(frame: frame, kind: .rasterizable, image: renderShapes(in: payload, unitSize: frame.size)))
                } else if isBareButton(frame, children) {
                    // A fill-less button (tertiary) has no shape, but its frame carries the real padded,
                    // min-width box — emit a transparent container so the label centers in it, not bare.
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

    // The corner radius of a clipShape(RoundedRectangle) effect — its FixedRoundedRect lives in the
    // effect payload (not the nested content), so search there without descending into child lists.
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

    // Round a fill leaf (a color/rect background) that the clip wraps — matched by frame.
    private static func rounded(_ leaf: DisplayLeaf, by radius: CGFloat, matching frame: CGRect) -> DisplayLeaf {
        guard abs(leaf.frame.width - frame.width) < 2, abs(leaf.frame.height - frame.height) < 2 else { return leaf }
        switch leaf.kind {
        case .color(let color): return DisplayLeaf(frame: leaf.frame, kind: .roundedRect(radius: radius, color: color))
        case .roundedRect(_, let color): return DisplayLeaf(frame: leaf.frame, kind: .roundedRect(radius: radius, color: color))
        default: return leaf
        }
    }

    // A fill-less button: a control-height group (taller than a label) wrapping only text/icon — its
    // frame is the real padded, min-width box, so keep it as a transparent container.
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
        // A button wraps a single label (plus an optional icon); a group of several texts is a layout
        // container — a stack of rows — not a button.
        guard textCount == 1 else { return false }
        // A button's box pads its label (or hits the control min-width); a multi-line wrapping label
        // fills its frame edge to edge. Only the padded case is a button — else it's just tall text.
        let content = children.map(\.frame).reduce(children[0].frame) { $0.union($1) }
        return (frame.width - content.width) / 2 > 4
    }

    // Fill one vector Path into a transparent PNG of the leaf's size — headless, no screen.
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

    // Render every shape in an icon/spinner subtree via CoreGraphics — headless, so no screen crop.
    // The DisplayList hands us the SwiftUI Path per shape; fill each at its position in the unit.
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
