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
                        .onAppear { onCapture(document(from: captured, proxy: proxy)) }
                        // Rasterized nodes (ImageRenderer) populate a frame later, adding to the
                        // set; re-write when the count changes so the image nodes are included.
                        .onChange(of: captured.count) { onCapture(document(from: captured, proxy: proxy)) }
                }
            }
    }

    // Maps the library's design-fact descriptors to fonno's Figma IR. All style comes
    // from the component (`PinCapturedComponent`), nothing re-specified here.
    private func document(from captured: [PinCapturedComponent], proxy: GeometryProxy) -> FigmaDocument {
        let size = proxy.size
        let children = captured.map { item -> FigmaNode in
            let style = item.style
            let rect = proxy[item.bounds]
            if let image = item.image {
                return FigmaNode(
                    tag: "image", x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                    component: style.name, image: image, children: []
                )
            }
            let fillColor = style.fillTokenName.flatMap { PinColorToken(rawValue: $0)?.color }
            let texts = style.text.map { string -> [FigmaText] in
                // The calibration target is the text's own iOS width. For a label that's the
                // node width; for a centered button the node is the padded pill, so measure
                // the label text itself.
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
        // A ScrollView's proxy reports only the viewport; eager content lays out in full and its
        // anchors carry real below-the-fold y, so size the frame to the content, not the viewport.
        let contentTop = children.map(\.y).min() ?? 0
        let contentBottom = children.map { $0.y + $0.h }.max() ?? size.height
        let height = max(size.height, contentBottom + contentTop)
        let root = FigmaNode(
            tag: "screen",
            x: 0, y: 0, w: size.width, h: height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            name: name,
            children: children
        )
        return FigmaDocument(
            width: size.width, height: height, root: root,
            tokens: Self.tokens, textStyles: PinTextStyle.allCapturable.map { FigmaTextStyle($0) }
        )
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

    // Off-screen rasterization is unreliable for native controls (ImageRenderer draws a
    // placeholder; a hosted copy renders blank). The content is already on-screen, so snapshot
    // the real window and crop to its frame — the actual pixels, native controls included.
    @MainActor private func render(_ frame: CGRect) {
        guard frame.width > 1, frame.height > 1,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }
        let full = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        guard let cgImage = full.cgImage else { return }
        let scale = full.scale
        let crop = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                          width: frame.width * scale, height: frame.height * scale)
        guard let cropped = cgImage.cropping(to: crop) else { return }
        base64 = UIImage(cgImage: cropped).pngData()?.base64EncodedString()
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
