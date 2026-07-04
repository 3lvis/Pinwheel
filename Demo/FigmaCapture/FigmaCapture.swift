import SwiftUI
import UIKit
import Pinwheel

// SPIKE — proves SwiftUI → fonno's Figma-import JSON. Emits the same schema
// `capture.json` that fonno/frontend/tools/figma-capture/plugin/code.ts rebuilds
// into Figma component instances, so that plugin is reused unchanged.
// See SPIKE-FIGMA-CAPTURE.md for what's proven vs. what productionizing needs.

// MARK: - fonno IR (mirrors the JSON tree capture.mjs emits)

struct FigmaDocument: Encodable {
    let width: Double
    let height: Double
    let root: FigmaNode
    let tokens: [FigmaToken]
    let textStyles: [FigmaTextStyle]
}

struct FigmaNode: Encodable {
    var tag: String
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var fill: RGBA?
    var fillToken: String?
    var radius: Double?
    var component: String?
    var name: String?
    var font: FigmaFont?
    var texts: [FigmaText]?
    var textAlign: String?
    var image: String?
    var children: [FigmaNode]
}

struct RGBA: Encodable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
}

struct FigmaFont: Encodable {
    let family: String
    let size: Double
    let weight: Int
    let color: RGBA
    let colorToken: String?
    let style: String?
}

struct FigmaTextStyle: Encodable {
    let name: String
    let family: String
    let size: Double
    let weight: Int
}

struct FigmaText: Encodable {
    let text: String
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}

struct FigmaToken: Encodable {
    let name: String
    let type: String
    let value: RGBA
}

extension RGBA {
    // Resolve against light mode for the spike; a full capture would emit both modes.
    init(_ color: Color) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

// Resolves the real provider-backed font so the capture matches what the component renders,
// instead of a hand-passed size/weight. Uses the demo's own provider (the library's `UIFont`
// token accessors aren't public).
extension PinTextStyle {
    @MainActor var demoUIFont: UIFont {
        let provider = DemoFontProvider()
        switch self {
        case .title: return provider.title
        case .subtitle: return provider.subtitle
        case .subtitleSemibold: return provider.subtitleSemibold
        case .body: return provider.body
        case .footnote: return provider.footnote
        case .caption: return provider.caption
        }
    }

    var captureName: String {
        switch self {
        case .title: return "title"
        case .subtitle: return "subtitle"
        case .subtitleSemibold: return "subtitleSemibold"
        case .body: return "body"
        case .footnote: return "footnote"
        case .caption: return "caption"
        }
    }

    // The design uses SF Pro Rounded; the system font's internal family name isn't
    // Figma-loadable, and the plugin falls back to Inter if the face is absent.
    @MainActor var captureMetrics: (family: String, size: Double, weight: Int) {
        let font = demoUIFont
        let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        let weight = (traits?[.weight] as? CGFloat) ?? 0
        return ("SF Pro Rounded", Double(font.pointSize), figmaCssWeight(weight))
    }

    static let allCapturable: [PinTextStyle] = [.title, .subtitle, .subtitleSemibold, .body, .footnote, .caption]
}

private func figmaCssWeight(_ weight: CGFloat) -> Int {
    switch weight {
    case ..<(-0.5): return 200
    case ..<(-0.2): return 300
    case ..<0.15: return 400
    case ..<0.28: return 500
    case ..<0.37: return 600
    case ..<0.5: return 700
    default: return 800
    }
}

extension FigmaFont {
    @MainActor init(_ textStyle: PinTextStyle, colorTokenName: String?) {
        let metrics = textStyle.captureMetrics
        let color = colorTokenName.flatMap { PinColorToken(rawValue: $0)?.color } ?? .primary
        self.init(
            family: metrics.family, size: metrics.size, weight: metrics.weight,
            color: RGBA(color), colorToken: colorTokenName, style: textStyle.captureName
        )
    }
}

extension FigmaTextStyle {
    @MainActor init(_ style: PinTextStyle) {
        let metrics = style.captureMetrics
        self.init(name: style.captureName, family: metrics.family, size: metrics.size, weight: metrics.weight)
    }
}

struct FigmaCaptureHost<Content: SwiftUI.View>: SwiftUI.View {
    let name: String
    let content: Content
    let onCapture: (FigmaDocument) -> Void

    var body: some SwiftUI.View {
        content
            .backgroundPreferenceValue(PinCaptureKey.self) { captured in
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { capture(captured, proxy) }
                        // CapturedImageView fills its image later, changing the count; re-capture
                        // so those image nodes are included.
                        .onChange(of: captured.count) { capture(captured, proxy) }
                }
            }
    }

    // Native-bit markers (a switch, a chevron) carry no image — the host photographs them here,
    // keeping the window-capture out of the library. Defer so the window is drawn, crop each
    // marker's on-screen frame (its anchor offset by the reader's global origin), then emit.
    private func capture(_ captured: [PinCapturedComponent], _ proxy: GeometryProxy) {
        guard captured.contains(where: { $0.needsRasterization }) else {
            onCapture(document(from: captured, proxy: proxy, rasterImages: [:]))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let origin = proxy.frame(in: .global).origin
            var rasterImages: [Int: String] = [:]
            for (index, item) in captured.enumerated() where item.needsRasterization {
                let global = proxy[item.bounds].offsetBy(dx: origin.x, dy: origin.y)
                if let base64 = ScreenCrop.base64(of: global) { rasterImages[index] = base64 }
            }
            onCapture(document(from: captured, proxy: proxy, rasterImages: rasterImages))
        }
    }

    // Maps the library's design-fact descriptors to fonno's Figma IR. All style comes
    // from the component (`PinCapturedComponent`), nothing re-specified here. Container nodes
    // (list rows) become parent frames; every other node nests under the smallest container whose
    // frame encloses it, so a row rebuilds as one Figma frame holding its labels/controls.
    private func document(from captured: [PinCapturedComponent], proxy: GeometryProxy, rasterImages: [Int: String]) -> FigmaDocument {
        let size = proxy.size
        // Resolve each descriptor to a node; drop rasterization markers we couldn't photograph
        // (off-screen when captured) so they don't become empty placeholder nodes.
        var nodes: [(rect: CGRect, isContainer: Bool, node: FigmaNode)] = []
        for (index, item) in captured.enumerated() {
            let resolvedImage = item.image ?? rasterImages[index]
            if item.needsRasterization && resolvedImage == nil { continue }
            let rect = proxy[item.bounds]
            nodes.append((rect: rect, isContainer: item.isContainer, node: node(for: item, rect: rect, resolvedImage: resolvedImage)))
        }

        // Innermost-first, so a node lands in the tightest container that encloses it.
        let containers = nodes.indices
            .filter { nodes[$0].isContainer }
            .sorted { nodes[$0].rect.width * nodes[$0].rect.height < nodes[$1].rect.width * nodes[$1].rect.height }
        func parent(of index: Int) -> Int? {
            containers.first { $0 != index && encloses(nodes[$0].rect, nodes[index].rect) }
        }

        var childIndices: [Int: [Int]] = [:]
        var topLevel: [Int] = []
        for index in nodes.indices {
            if let owner = parent(of: index) { childIndices[owner, default: []].append(index) }
            else { topLevel.append(index) }
        }
        // Smallest-first: an inner container is populated before an outer one reads it as a child.
        for owner in containers {
            nodes[owner].node.children = (childIndices[owner] ?? []).map { nodes[$0].node }
        }

        // A ScrollView's proxy reports only the viewport; eager content lays out in full and its
        // anchors carry real below-the-fold y, so size the frame to the content, not the viewport.
        let contentTop = nodes.map { $0.rect.minY }.min() ?? 0
        let contentBottom = nodes.map { $0.rect.maxY }.max() ?? size.height
        let height = max(size.height, contentBottom + contentTop)
        let root = FigmaNode(
            tag: "screen",
            x: 0, y: 0, w: size.width, h: height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            name: name,
            children: topLevel.map { nodes[$0].node }
        )
        return FigmaDocument(
            width: size.width, height: height, root: root,
            tokens: Self.tokens, textStyles: PinTextStyle.allCapturable.map { FigmaTextStyle($0) }
        )
    }

    // One IR node for a captured descriptor: a rasterized image, a group frame (a container, e.g.
    // a row — children nested by the caller), or a structured leaf (label/button).
    private func node(for item: PinCapturedComponent, rect: CGRect, resolvedImage: String?) -> FigmaNode {
        let style = item.style
        let fillColor = style.fillTokenName.flatMap { PinColorToken(rawValue: $0)?.color }

        if let image = resolvedImage {
            return FigmaNode(
                tag: "image", x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                component: style.name, image: image, children: []
            )
        }
        if item.isContainer {
            // A component keyed by the row's structural name: the plugin builds the first as a master
            // and the rest as instances that override only their text — so repeated rows reuse one
            // component, and the master's native bit (chevron/switch) is inherited, not re-captured.
            return FigmaNode(
                tag: "component", x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                fill: fillColor.map { RGBA($0) }, fillToken: style.fillTokenName,
                radius: style.cornerRadius.map { Double($0) },
                component: style.name, children: []
            )
        }
        let texts = style.text.map { string -> [FigmaText] in
            // The calibration target is the text's own iOS width. For a label that's the node
            // width; for a centered button the node is the padded pill, so measure the label itself.
            let textWidth = style.centersText
                ? Double((string as NSString).size(withAttributes: [.font: (style.textStyle ?? .body).demoUIFont]).width)
                : rect.width
            return [FigmaText(text: string, x: rect.minX, y: rect.minY, w: textWidth, h: rect.height)]
        }
        return FigmaNode(
            tag: "component",
            x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
            fill: fillColor.map { RGBA($0) },
            fillToken: style.fillTokenName,
            radius: style.cornerRadius.map { Double($0) },
            component: style.name,
            font: style.textStyle.map { FigmaFont($0, colorTokenName: style.textColorTokenName) },
            texts: texts,
            textAlign: style.centersText ? "center" : nil,
            children: []
        )
    }

    private func encloses(_ outer: CGRect, _ inner: CGRect) -> Bool {
        let tolerance = 0.5
        return outer.minX - tolerance <= inner.minX && outer.minY - tolerance <= inner.minY
            && outer.maxX + tolerance >= inner.maxX && outer.maxY + tolerance >= inner.maxY
    }

    private static var tokens: [FigmaToken] {
        PinColorToken.allCases.map { FigmaToken(name: $0.rawValue, type: "color", value: RGBA($0.color)) }
    }
}

// Rasterizes any view (native controls, images, SF Symbols) to a PNG and emits it through the
// same `PinCaptureKey` as structured components, so the host places it at its real frame.
struct CapturedImageView<Content: SwiftUI.View>: SwiftUI.View {
    let name: String
    let content: Content
    @State private var base64: String?

    init(_ name: String, @ViewBuilder content: () -> Content) {
        self.name = name
        self.content = content()
    }

    var body: some SwiftUI.View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        let frame = proxy.frame(in: .global)
                        // Defer so the on-screen content (native controls included) is fully drawn.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { render(frame) }
                    }
                }
            )
            .anchorPreference(key: PinCaptureKey.self, value: .bounds) { anchor in
                guard let base64 else { return [] }
                return [PinCapturedComponent(
                    style: PinComponentStyle(
                        name: name, text: nil, textStyle: nil, textColorTokenName: nil,
                        fillTokenName: nil, cornerRadius: nil, centersText: false
                    ),
                    bounds: anchor,
                    image: base64
                )]
            }
    }

    @MainActor private func render(_ frame: CGRect) {
        base64 = ScreenCrop.base64(of: frame)
    }
}

// Crops a global-coordinate rect out of the key window's rendered pixels. Off-screen rasterization
// is unreliable for native controls (ImageRenderer draws a placeholder; a hosted copy renders
// blank), so snapshot the real on-screen window and crop — the actual pixels, native controls
// included. Returns nil when the rect is off-screen (nothing to crop).
enum ScreenCrop {
    @MainActor static func base64(of frame: CGRect) -> String? {
        guard frame.width > 1, frame.height > 1,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return nil }
        let full = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        guard let cgImage = full.cgImage else { return nil }
        let scale = full.scale
        let crop = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                          width: frame.width * scale, height: frame.height * scale)
        guard let cropped = cgImage.cropping(to: crop) else { return nil }
        return UIImage(cgImage: cropped).pngData()?.base64EncodedString()
    }
}

enum FigmaCaptureFile {
    static func write(_ document: FigmaDocument) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(document),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        try? data.write(to: directory.appendingPathComponent("figma-capture.json"))
        push(data)
    }

    // Best-effort push to the local capture serve so the plugin's "Import layers" is always the
    // latest render — no manual pull. Silently no-ops when the serve isn't running.
    private static func push(_ data: Data) {
        post("http://localhost:8787/capture.json", data)
    }

    // Push one catalog item's capture (keyed by id, with its metadata) so the serve accumulates a
    // manifest the plugin lists — the many-components counterpart of the single-screen push.
    static func pushCatalog(id: String, title: String, section: String, tags: [String], document: FigmaDocument) {
        let entry = CatalogEntry(id: id, title: title, section: section, tags: tags, document: document)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entry) else { return }
        post("http://localhost:8787/catalog", data)
    }

    private static func post(_ urlString: String, _ data: Data) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        URLSession.shared.dataTask(with: request).resume()
    }

    private struct CatalogEntry: Encodable {
        let id: String
        let title: String
        let section: String
        let tags: [String]
        let document: FigmaDocument
    }
}
