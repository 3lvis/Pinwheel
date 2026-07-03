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
    var font: FigmaFont?
    var texts: [FigmaText]?
    var textAlign: String?
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

// The closed set of Pinwheel color tokens. A captured component names the token it uses, so
// Figma binds to the variable by name — no fragile colour-value matching.
enum PinColorToken: String, CaseIterable {
    case primaryText, secondaryText, tertiaryText, actionText, criticalText
    case primaryBackground, secondaryBackground, actionBackground, criticalBackground

    var color: Color {
        switch self {
        case .primaryText: return .primaryText
        case .secondaryText: return .secondaryText
        case .tertiaryText: return .tertiaryText
        case .actionText: return .actionText
        case .criticalText: return .criticalText
        case .primaryBackground: return .primaryBackground
        case .secondaryBackground: return .secondaryBackground
        case .actionBackground: return .actionBackground
        case .criticalBackground: return .criticalBackground
        }
    }
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
    let content: Content
    let onCapture: (FigmaDocument) -> Void

    var body: some SwiftUI.View {
        content
            .backgroundPreferenceValue(PinCaptureKey.self) { captured in
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        onCapture(document(from: captured, proxy: proxy))
                    }
                }
            }
    }

    // Maps the library's design-fact descriptors to fonno's Figma IR. All style comes
    // from the component (`PinCapturedComponent`), nothing re-specified here.
    private func document(from captured: [PinCapturedComponent], proxy: GeometryProxy) -> FigmaDocument {
        let size = proxy.size
        let children = captured.map { item -> FigmaNode in
            let rect = proxy[item.bounds]
            let fillColor = item.fillTokenName.flatMap { PinColorToken(rawValue: $0)?.color }
            let texts = item.text.map { string -> [FigmaText] in
                // The calibration target is the text's own iOS width. For a label that's the
                // node width; for a centered button the node is the padded pill, so measure
                // the label text itself.
                let textWidth = item.centersText
                    ? Double((string as NSString).size(withAttributes: [.font: (item.textStyle ?? .body).demoUIFont]).width)
                    : rect.width
                return [FigmaText(text: string, x: rect.minX, y: rect.minY, w: textWidth, h: rect.height)]
            }
            return FigmaNode(
                tag: "component",
                x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                fill: fillColor.map { RGBA($0) },
                fillToken: item.fillTokenName,
                radius: item.cornerRadius.map { Double($0) },
                component: item.name,
                font: item.textStyle.map { FigmaFont($0, colorTokenName: item.textColorTokenName) },
                texts: texts,
                textAlign: item.centersText ? "center" : nil,
                children: []
            )
        }
        let root = FigmaNode(
            tag: "screen",
            x: 0, y: 0, w: size.width, h: size.height,
            fill: RGBA(PinColorToken.primaryBackground.color),
            fillToken: PinColorToken.primaryBackground.rawValue,
            children: children
        )
        return FigmaDocument(
            width: size.width, height: size.height, root: root,
            tokens: Self.tokens, textStyles: PinTextStyle.allCapturable.map { FigmaTextStyle($0) }
        )
    }

    private static var tokens: [FigmaToken] {
        PinColorToken.allCases.map { FigmaToken(name: $0.rawValue, type: "color", value: RGBA($0.color)) }
    }
}

enum FigmaCaptureFile {
    static var requested: Bool {
        ProcessInfo.processInfo.arguments.contains("-FigmaCapture")
    }

    static func write(_ document: FigmaDocument) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(document),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        try? data.write(to: directory.appendingPathComponent("figma-capture.json"))
    }
}
