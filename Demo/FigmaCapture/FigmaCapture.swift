import SwiftUI
import UIKit
import Pinwheel

// SwiftUI → the JSON IR the fonno Figma plugin imports. See SPIKE-FIGMA-CAPTURE.md.

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
    var layout: FigmaLayout?
    var children: [FigmaNode]
}

struct FigmaLayout: Encodable {
    let mode: String
    let columnGap: Double
    let rowGap: Double
    let pad: [Double]
    let justify: String
    let align: String
    let primarySizing: String
    let counterSizing: String

    @MainActor init(_ layout: PinCaptureLayout) {
        let horizontal = layout.axis == .row
        mode = horizontal ? "row" : "column"
        columnGap = horizontal ? Double(layout.spacing) : 0
        rowGap = horizontal ? 0 : Double(layout.spacing)
        pad = [Double(layout.padding.top), Double(layout.padding.trailing),
               Double(layout.padding.bottom), Double(layout.padding.leading)]
        justify = layout.spaceBetween ? "space-between" : "flex-start"
        switch layout.alignment {
        case .leading: align = "flex-start"
        case .center: align = "center"
        case .trailing: align = "flex-end"
        }
        primarySizing = layout.spaceBetween ? "FIXED" : "AUTO"
        counterSizing = "AUTO"
    }
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
    let dark: RGBA?
}

extension RGBA {
    init(_ color: Color, style: UIUserInterfaceStyle = .light) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

// Uses the demo's own provider — the library's UIFont token accessors aren't public.
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

    // The system font's internal family name isn't Figma-loadable, so name the design face explicitly.
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
    @MainActor init(_ textStyle: PinTextStyle, colorTokenName: String?, rawColor: Color? = nil) {
        let metrics = textStyle.captureMetrics
        let color = colorTokenName.flatMap { PinColorToken(rawValue: $0)?.color } ?? rawColor ?? .primary
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
            .environment(\.pinCapturing, true)
            .backgroundPreferenceValue(PinCaptureKey.self) { captured in
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { capture(captured, proxy) }
                        // CapturedImageView fills its image later (changing the count); re-capture to include it.
                        .onChange(of: captured.count) { capture(captured, proxy) }
                }
            }
    }

    // A structured capture with no content nodes means UIKit-hosted lazy content (a real
    // `UIKitPinTableView`) that emits no descriptors — page its scroll view and stitch instead.
    private func deliver(_ document: FigmaDocument) {
        if document.root.children.isEmpty {
            Task { await scrollStitchFallback() }
        } else {
            onCapture(document)
        }
    }

    @MainActor
    private func scrollStitchFallback() async {
        var attempts = 0
        while attempts < 600 {
            attempts += 1
            if let window = ScreenCrop.keyWindow(),
               let scroll = ScrollStitch.scrollView(in: window),
               scroll.bounds.height > 1, scroll.contentSize.height > scroll.bounds.height + 1 {
                if let result = await ScrollStitch.capture(scroll, in: window) {
                    onCapture(stitchedDocument(result))
                }
                return
            }
            await Task.yield()
        }
    }

    private func stitchedDocument(_ result: (pages: [ScrollStitch.Page], size: CGSize)) -> FigmaDocument {
        let children = result.pages.compactMap { page -> FigmaNode? in
            guard let base64 = page.image.pngData()?.base64EncodedString() else { return nil }
            return FigmaNode(
                tag: "image", x: 0, y: page.offset, w: result.size.width, h: page.height,
                component: "\(name)Rows", image: base64, children: []
            )
        }
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: result.size.width, h: result.size.height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            name: name, children: children
        )
        return FigmaDocument(width: result.size.width, height: result.size.height, root: root, tokens: [], textStyles: [])
    }

    private func capture(_ captured: [PinCapturedComponent], _ proxy: GeometryProxy) {
        guard captured.contains(where: { $0.needsRasterization }) else {
            deliver(document(from: captured, proxy: proxy, rasterImages: [:]))
            return
        }
        // Native bits are photographed in the simulator's current appearance (set via `simctl ui …
        // appearance dark`); an in-app window flip doesn't work — SwiftUI's WindowGroup resets
        // overrideUserInterfaceStyle. A marker's frame is its anchor offset by the reader's origin.
        DispatchQueue.main.async {
            let origin = proxy.frame(in: .global).origin
            var images: [Int: String] = [:]
            for (index, item) in captured.enumerated() where item.needsRasterization {
                let global = proxy[item.bounds].offsetBy(dx: origin.x, dy: origin.y)
                if let base64 = ScreenCrop.base64(of: global) { images[index] = base64 }
            }
            deliver(document(from: captured, proxy: proxy, rasterImages: images))
        }
    }

    private func document(from captured: [PinCapturedComponent], proxy: GeometryProxy, rasterImages: [Int: String]) -> FigmaDocument {
        let size = proxy.size
        var nodes: [(rect: CGRect, isContainer: Bool, node: FigmaNode)] = []
        for (index, item) in captured.enumerated() {
            let resolvedImage = item.image ?? rasterImages[index]
            let nothingToPhotograph = item.needsRasterization && resolvedImage == nil
            if nothingToPhotograph { continue }
            let rect = proxy[item.bounds]
            nodes.append((rect: rect, isContainer: item.isContainer, node: node(for: item, rect: rect, resolvedImage: resolvedImage)))
        }

        let containersInnermostFirst = nodes.indices
            .filter { nodes[$0].isContainer }
            .sorted { nodes[$0].rect.width * nodes[$0].rect.height < nodes[$1].rect.width * nodes[$1].rect.height }
        func innermostContainer(enclosing index: Int) -> Int? {
            containersInnermostFirst.first { $0 != index && encloses(nodes[$0].rect, nodes[index].rect) }
        }

        var childIndices: [Int: [Int]] = [:]
        var topLevel: [Int] = []
        for index in nodes.indices {
            if let owner = innermostContainer(enclosing: index) { childIndices[owner, default: []].append(index) }
            else { topLevel.append(index) }
        }
        for owner in containersInnermostFirst {
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

    private func node(for item: PinCapturedComponent, rect: CGRect, resolvedImage: String?) -> FigmaNode {
        let style = item.style
        let fillColor = style.fillTokenName.flatMap { PinColorToken(rawValue: $0)?.color } ?? style.fillColor

        if let image = resolvedImage {
            return FigmaNode(
                tag: "image", x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                component: style.name, image: image, children: []
            )
        }
        if item.isContainer {
            return FigmaNode(
                tag: "component", x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                fill: fillColor.map { RGBA($0) }, fillToken: style.fillTokenName,
                radius: style.cornerRadius.map { Double($0) },
                component: style.name,
                layout: item.layout.map { FigmaLayout($0) },
                children: []
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
            font: style.textStyle.map { FigmaFont($0, colorTokenName: style.textColorTokenName, rawColor: style.textColor) },
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
        PinColorToken.allCases.map {
            FigmaToken(name: $0.rawValue, type: "color", value: RGBA($0.color, style: .light), dark: RGBA($0.color, style: .dark))
        }
    }
}

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
                        // Next runloop: drawHierarchy(afterScreenUpdates: true) in render() flushes the
                        // control's draw before snapshotting, so no wall-clock settle is needed.
                        DispatchQueue.main.async { render(frame) }
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

// ImageRenderer draws a placeholder for native controls and an off-screen host renders blank, so
// snapshot the real on-screen window and crop the marker's rect out of it.
enum ScreenCrop {
    @MainActor static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    @MainActor static func base64(of frame: CGRect) -> String? {
        guard frame.width > 1, frame.height > 1, let window = keyWindow() else { return nil }
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

    // Best-effort, fire-and-forget: no-ops if the serve isn't running.
    private static func push(_ data: Data) {
        post("http://localhost:8787/capture.json", data)
    }

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
