import SwiftUI
import UIKit
import Pinwheel

// SwiftUI → the JSON IR the fonno Figma plugin imports. See SPIKE-FIGMA-CAPTURE.md.

enum FigmaCaptureFormat {
    // Bump when the IR shape changes; the plugin flags a capture whose version it doesn't expect.
    static let version = 1
}

public struct FigmaDocument: Encodable {
    let version = FigmaCaptureFormat.version
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
    var opacity: Double?
    var image: String?
    var layout: FigmaLayout?
    var grow: Bool?
    var ordered: Bool?
    var fillWidth: Bool?
    var children: [FigmaNode]
}

struct FigmaLayout: Encodable {
    var mode: String
    var columnGap: Double
    var rowGap: Double
    var pad: [Double]
    var justify: String
    var align: String
    var primarySizing: String
    var counterSizing: String
    var minWidth: Double?

    @MainActor init(_ layout: PinCaptureLayout) {
        let horizontal = layout.axis == .row
        mode = horizontal ? "row" : "column"
        columnGap = horizontal ? Double(layout.spacing) : 0
        rowGap = horizontal ? 0 : Double(layout.spacing)
        pad = [Double(layout.padding.top), Double(layout.padding.trailing),
               Double(layout.padding.bottom), Double(layout.padding.leading)]
        func css(_ crossAxis: PinCaptureLayout.CrossAxis) -> String {
            switch crossAxis {
            case .leading: return "flex-start"
            case .center: return "center"
            case .trailing: return "flex-end"
            }
        }
        justify = layout.spaceBetween ? "space-between" : css(layout.mainAxisAlignment)
        align = css(layout.alignment)
        primarySizing = layout.spaceBetween ? "FIXED" : "AUTO"
        counterSizing = "AUTO"
        minWidth = layout.minWidth.map(Double.init)
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
    let underline: Bool
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
    init(_ uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }

    init(_ color: Color, style: UIUserInterfaceStyle = .light) {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

extension PinTextStyle {
    @MainActor var captureUIFont: UIFont {
        switch self {
        case .title: return .title
        case .subtitle: return .subtitle
        case .subtitleSemibold: return .subtitleSemibold
        case .body: return .body
        case .footnote: return .footnote
        case .caption: return .caption
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
        let font = captureUIFont
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
    @MainActor init(_ textStyle: PinTextStyle, colorTokenName: String?, rawColor: Color? = nil, underline: Bool = false) {
        let metrics = textStyle.captureMetrics
        let color = colorTokenName.flatMap { PinColorToken(rawValue: $0)?.color } ?? rawColor ?? .primary
        self.init(
            family: metrics.family, size: metrics.size, weight: metrics.weight,
            color: RGBA(color), colorToken: colorTokenName, style: textStyle.captureName, underline: underline
        )
    }
}

extension FigmaTextStyle {
    @MainActor init(_ style: PinTextStyle) {
        let metrics = style.captureMetrics
        self.init(name: style.captureName, family: metrics.family, size: metrics.size, weight: metrics.weight)
    }
}

// Best-effort, fire-and-forget pushes to the local serve: no-op if it isn't running.
public enum FigmaCaptureFile {
    public static func pushCatalog(id: String, title: String, section: String, tags: [String], document: FigmaDocument) {
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
