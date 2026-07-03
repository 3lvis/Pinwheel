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

// MARK: - Capture pass

// Each annotated view reports its descriptor plus a bounds anchor; the host
// resolves the anchor to a frame in the screen's coordinate space.
struct CapturedComponent {
    let component: String
    let fill: RGBA?
    let fillToken: String?
    let radius: Double?
    let text: String?
    let font: FigmaFont?
    let bounds: Anchor<CGRect>
}

private struct CapturePreferenceKey: PreferenceKey {
    static let defaultValue: [CapturedComponent] = []
    static func reduce(value: inout [CapturedComponent], nextValue: () -> [CapturedComponent]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    // In the spike the composition site tags each component; productionizing moves
    // this inside the `Pin*` views so they self-identify (no call-site tagging).
    func figmaCapture(
        component: String,
        fillToken: PinColorToken? = nil,
        radius: Double? = nil,
        text: String? = nil,
        textColorToken: PinColorToken = .primaryText,
        fontSize: Double? = nil,
        fontWeight: Int = 400,
        fontFamily: String = "SF Pro Rounded"
    ) -> some View {
        let font = fontSize.map {
            FigmaFont(
                family: fontFamily, size: $0, weight: fontWeight,
                color: RGBA(textColorToken.color), colorToken: textColorToken.rawValue
            )
        }
        return anchorPreference(key: CapturePreferenceKey.self, value: .bounds) { anchor in
            [CapturedComponent(
                component: component,
                fill: fillToken.map { RGBA($0.color) },
                fillToken: fillToken?.rawValue,
                radius: radius,
                text: text,
                font: font,
                bounds: anchor
            )]
        }
    }
}

struct FigmaCaptureHost<Content: SwiftUI.View>: SwiftUI.View {
    let content: Content
    let onCapture: (FigmaDocument) -> Void

    var body: some SwiftUI.View {
        content
            .backgroundPreferenceValue(CapturePreferenceKey.self) { captured in
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        onCapture(document(from: captured, proxy: proxy))
                    }
                }
            }
    }

    private func document(from captured: [CapturedComponent], proxy: GeometryProxy) -> FigmaDocument {
        let size = proxy.size
        let children = captured.map { item -> FigmaNode in
            let rect = proxy[item.bounds]
            return FigmaNode(
                tag: "component",
                x: rect.minX, y: rect.minY, w: rect.width, h: rect.height,
                fill: item.fill,
                fillToken: item.fillToken,
                radius: item.radius,
                component: item.component,
                font: item.font,
                texts: item.text.map { [FigmaText(text: $0, x: rect.minX, y: rect.minY, w: rect.width, h: rect.height)] },
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
        return FigmaDocument(width: size.width, height: size.height, root: root, tokens: Self.tokens)
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
