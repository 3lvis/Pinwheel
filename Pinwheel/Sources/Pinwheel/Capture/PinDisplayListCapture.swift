import SwiftUI
import UIKit
import Pinwheel

// Turns the DisplayList leaves into the Figma IR — a nested auto-layout tree — with no capture
// markers in the view. Containment groups leaves (a pill encloses its label/icon; a card encloses
// its buttons); axis/spacing/alignment are inferred from the frames SwiftUI already computed.
@MainActor
public enum PinDisplayListCapture {
    public static func document<Content: SwiftUI.View>(_ view: Content, name: String, size: CGSize) -> FigmaDocument? {
        guard let (leaves, host, window) = PinDisplayList.read(view, size: size) else { return nil }
        return withExtendedLifetime(window) { build(view, leaves: leaves, host: host, size: size) }
    }

    private static func build<Content: SwiftUI.View>(_ view: Content, leaves: [DisplayLeaf], host: UIView, size: CGSize) -> FigmaDocument? {
        // The screen fill spans the full hosting height; trim it to the content so the root frame
        // (and its bottom padding) match the real screen, not the oversized host.
        let contentBottom = (leaves.map { $0.frame.maxY }.filter { $0 < size.height - 1 }.max() ?? size.height)
        let trimmed = leaves.map { leaf in
            leaf.frame.height >= size.height - 1
                ? DisplayLeaf(frame: CGRect(x: leaf.frame.minX, y: leaf.frame.minY, width: leaf.frame.width, height: contentBottom + 24), kind: leaf.kind)
                : leaf
        }
        let root = containmentTree(trimmed)
        let components = orderedComponents(root)
        let screenFill = fillColor(root.leaf.kind)

        // Value-reflection supplies the semantic auto-layout tree (native VStack/HStack leave no
        // drawable to group by); the DisplayList supplies each leaf's exact appearance. Zip the
        // reflected leaves with the rendered components by order. Fall back to pure containment if
        // the counts disagree (reflection couldn't cleanly account for the rendered leaves).
        if let structure = PinViewReflector.reflect(view), leafCount(structure) == components.count {
            var pool = components
            let backgrounds = collectBackgrounds(root)
            let content = emitStructure(structure, host: host, backgrounds: backgrounds) { text in
                // Match by content, not position — a 2D grid scrambles a positional zip. Duplicate
                // texts resolve by order (first unconsumed); fall back to order if no text matches.
                let matched = pool.firstIndex { componentText($0) == text } ?? (pool.isEmpty ? nil : 0)
                return matched.map { pool.remove(at: $0) }
            }
            if let content {
                let rootNode = screen(content, width: size.width, fill: screenFill, components: components)
                return FigmaDocument(width: size.width, height: rootNode.h, root: rootNode, tokens: colorTokens, textStyles: [])
            }
        }

        let rootNode = emit(root, host: host)
        return FigmaDocument(width: size.width, height: rootNode.h, root: rootNode, tokens: colorTokens, textStyles: [])
    }

    private static func leafCount(_ node: ReflectedNode) -> Int {
        switch node {
        case .leaf: return 1
        case .spacer: return 0
        case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
        }
    }

    // Flatten the containment forest to leaf-level components in render order: a pill/label/image is a
    // component; a shape that groups other components (a card background) is recursed through.
    private static func orderedComponents(_ box: Box) -> [Box] {
        groupOrphanIcons(flatten(box))
    }

    private static func flatten(_ box: Box) -> [Box] {
        let groupsOthers = box.children.contains { !$0.children.isEmpty }
        if box.children.isEmpty || !groupsOthers { return [box] }
        return orderedForLayout(box.children).flatMap(flatten)
    }

    // A fill-less button (tertiary) has no pill to enclose its label + icon, so they arrive as two
    // adjacent orphan leaves — regroup an icon that sits on the same row next to a text.
    private static func groupOrphanIcons(_ components: [Box]) -> [Box] {
        var result: [Box] = []
        var index = 0
        while index < components.count {
            let current = components[index]
            if index + 1 < components.count, isBareText(current), isBareImage(components[index + 1]),
               sameRow(current.leaf.frame, components[index + 1].leaf.frame) {
                let group = Box(DisplayLeaf(frame: current.leaf.frame.union(components[index + 1].leaf.frame), kind: .transparent))
                group.children = [current, components[index + 1]]
                result.append(group)
                index += 2
            } else {
                result.append(current)
                index += 1
            }
        }
        return result
    }

    private static func componentText(_ box: Box) -> String? {
        if case .text(let string, _, _, _) = box.leaf.kind { return string }
        for child in box.children { if let text = componentText(child) { return text } }
        return nil
    }

    private static func isBareText(_ box: Box) -> Bool {
        if case .text = box.leaf.kind, box.children.isEmpty { return true }
        return false
    }
    private static func isBareImage(_ box: Box) -> Bool {
        if case .rasterizable = box.leaf.kind, box.children.isEmpty { return true }
        return false
    }
    private static func sameRow(_ a: CGRect, _ b: CGRect) -> Bool {
        let overlapY = a.minY < b.maxY && b.minY < a.maxY
        let gap = min(abs(b.minX - a.maxX), abs(a.minX - b.maxX))
        return overlapY && gap < 24
    }

    private static func emitStructure(_ node: ReflectedNode, host: UIView, backgrounds: [Background], next: (String?) -> Box?) -> FigmaNode? {
        switch node {
        case .leaf(let text, let isButton, let fillWidth):
            guard let box = next(text) else { return nil }
            var node = componentNode(box, host: host)
            // A fill-less button whose frame SwiftUI dropped comes back as bare text — rebuild its
            // padded, min-width, centered box so it reads as a button, not a loose label.
            if isButton, node.tag != "frame" { node = bareButtonContainer(node) }
            if fillWidth { node = fillWidthCentered(node) }
            return node
        case .spacer:
            return FigmaNode(tag: "spacer", x: 0, y: 0, w: 0, h: 0, grow: true, children: [])
        case .container(let container, let children):
            let childNodes = children.compactMap { emitStructure($0, host: host, backgrounds: backgrounds, next: next) }
            guard childNodes.contains(where: { $0.grow != true }) else { return nil }
            // A decorative background (a card) is a filled shape reflection sees as a transparent
            // container — re-attach its fill/radius/padding by matching the text set it wraps.
            let texts = childNodes.reduce(into: Set<String>()) { $0.formUnion(nodeTexts($1)) }
            let background = backgrounds.first { $0.texts == texts }
            var layout = PinCaptureLayout(
                axis: container.axis, spacing: container.spacing ?? 8,
                padding: background?.padding ?? EdgeInsets(), alignment: container.alignment, mainAxisAlignment: .leading
            )
            return FigmaNode(
                tag: "frame", x: 0, y: 0, w: 0, h: 0,
                fill: background?.fill.map(RGBA.init), fillToken: background?.fill.flatMap(tokenName(for:)),
                radius: background?.radius.map(Double.init),
                name: container.axis == .row ? "HStack" : "VStack",
                layout: FigmaLayout(layout), ordered: true, children: childNodes
            )
        }
    }

    // Wrap a lone label/icon in the pill box SwiftUI optimized away for a fill-less button: the
    // control's min-width and standard padding, content centered. Transparent (tertiary has no fill).
    private static func bareButtonContainer(_ content: FigmaNode) -> FigmaNode {
        let layout = PinCaptureLayout(
            axis: .row, spacing: .spacingS,
            padding: EdgeInsets(top: .spacingM, leading: .spacingL, bottom: .spacingM, trailing: .spacingL),
            alignment: .center, mainAxisAlignment: .center, minWidth: PinButton.minTitledWidth
        )
        return FigmaNode(
            tag: "frame", x: content.x, y: content.y,
            w: max(content.w + 2 * Double(CGFloat.spacingL), Double(PinButton.minTitledWidth)),
            h: content.h + 2 * Double(CGFloat.spacingM),
            name: "Pill", layout: FigmaLayout(layout), ordered: true, children: [content]
        )
    }

    // A `.frame(maxWidth: .infinity)` keeps the button's own width and centers it in the freed width —
    // so wrap it in a parent-filling frame that centers, rather than stretching the button itself.
    private static func fillWidthCentered(_ content: FigmaNode) -> FigmaNode {
        let layout = PinCaptureLayout(axis: .column, spacing: 0, padding: EdgeInsets(), alignment: .center, mainAxisAlignment: .center)
        var wrapper = FigmaNode(tag: "frame", x: content.x, y: content.y, w: 0, h: content.h, name: "Center", layout: FigmaLayout(layout), ordered: true, children: [content])
        wrapper.fillWidth = true
        return wrapper
    }

    // A filled shape that groups other components (a card) — reflection treats it as a transparent
    // container, so remember its fill/radius/padding keyed by the text set it wraps.
    private struct Background { let texts: Set<String>; let fill: UIColor?; let radius: CGFloat?; let padding: EdgeInsets }

    private static func collectBackgrounds(_ box: Box) -> [Background] {
        var result: [Background] = []
        func visit(_ box: Box) {
            let groupsOthers = box.children.contains { !$0.children.isEmpty }
            if groupsOthers, let fill = fillColor(box.leaf.kind) {
                let texts = box.children.reduce(into: Set<String>()) { $0.formUnion(boxTexts($1)) }
                let union = box.children.map(\.leaf.frame).reduce(nil, unite) ?? box.leaf.frame
                result.append(Background(
                    texts: texts, fill: fill, radius: cornerRadius(box.leaf.kind),
                    padding: EdgeInsets(top: max(union.minY - box.leaf.frame.minY, 0), leading: max(union.minX - box.leaf.frame.minX, 0),
                                        bottom: max(box.leaf.frame.maxY - union.maxY, 0), trailing: max(box.leaf.frame.maxX - union.maxX, 0))
                ))
            }
            box.children.forEach(visit)
        }
        visit(box)
        return result
    }

    private static func boxTexts(_ box: Box) -> Set<String> {
        var texts = Set<String>()
        if case .text(let string, _, _, _) = box.leaf.kind { texts.insert(string) }
        box.children.forEach { texts.formUnion(boxTexts($0)) }
        return texts
    }

    private static func nodeTexts(_ node: FigmaNode) -> Set<String> {
        var texts = Set(node.texts?.map(\.text) ?? [])
        node.children.forEach { texts.formUnion(nodeTexts($0)) }
        return texts
    }

    // A rendered component (from containment) → its Figma node: a pill is a filled auto-layout row of
    // its label/icon; a bare text or image is a leaf.
    private static func componentNode(_ box: Box, host: UIView) -> FigmaNode {
        let frame = box.leaf.frame
        if box.children.isEmpty {
            switch box.leaf.kind {
            case .text(let string, let font, let color, let underline):
                return FigmaNode(
                    tag: "text", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                    font: figmaFont(font, color: color, underline: underline),
                    texts: [FigmaText(text: string, x: frame.minX, y: frame.minY, w: frame.width, h: frame.height)],
                    children: []
                )
            case .rasterizable:
                return FigmaNode(tag: "image", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height, image: box.leaf.image, children: [])
            default:
                return filledRect(frame, radius: cornerRadius(box.leaf.kind), color: fillColor(box.leaf.kind))
            }
        }
        let ordered = orderedForLayout(box.children)
        let childNodes = ordered.map { componentNode($0, host: host) }
        let fill = fillColor(box.leaf.kind)
        var layout = inferLayout(ordered.map(\.leaf.frame), in: frame)
        // Keep the pill's rendered width (padding + min-width) so the hugging frame doesn't shrink.
        layout = PinCaptureLayout(axis: layout.axis, spacing: layout.spacing, padding: layout.padding, alignment: layout.alignment, mainAxisAlignment: .center, minWidth: frame.width)
        return FigmaNode(
            tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: fill.map(RGBA.init), fillToken: fill.flatMap(tokenName(for:)),
            radius: cornerRadius(box.leaf.kind).map(Double.init),
            name: "Pill", layout: FigmaLayout(layout), ordered: true, children: childNodes
        )
    }

    // The outer container becomes the screen: fixed to the device width (so centered content spans it)
    // and padded to where the content actually sits, with the screen fill behind.
    private static func screen(_ content: FigmaNode, width: CGFloat, fill: UIColor?, components: [Box]) -> FigmaNode {
        let minY = components.map { $0.leaf.frame.minY }.min() ?? 0
        let maxY = components.map { $0.leaf.frame.maxY }.max() ?? 0
        let minX = components.map { $0.leaf.frame.minX }.min() ?? 0
        var screenNode = content
        screenNode.tag = "screen"
        screenNode.x = 0
        screenNode.y = 0
        screenNode.w = Double(width)
        screenNode.h = Double(maxY + minY)
        screenNode.fill = fill.map(RGBA.init)
        screenNode.fillToken = fill.flatMap(tokenName(for:))
        if var layout = screenNode.layout {
            layout.pad = [Double(minY), Double(width) - Double(minX) - Double(components.map { $0.leaf.frame.maxX }.max() ?? 0) + Double(minX), Double(minY), Double(minX)]
            layout.primarySizing = "FIXED"
            layout.counterSizing = "FIXED"
            screenNode.layout = layout
        }
        return screenNode
    }

    private final class Box {
        let leaf: DisplayLeaf
        var children: [Box] = []
        init(_ leaf: DisplayLeaf) { self.leaf = leaf }
        var area: CGFloat { leaf.frame.width * leaf.frame.height }
    }

    // Nest each leaf under the smallest already-placed leaf that encloses it (largest-first ensures
    // a potential parent is seen before its children). The biggest leaf — the screen fill — is the root.
    private static func containmentTree(_ leaves: [DisplayLeaf]) -> Box {
        let boxes = leaves.map(Box.init).sorted { $0.area > $1.area }
        for (index, box) in boxes.enumerated() {
            let parent = boxes[..<index].last { encloses($0.leaf.frame, box.leaf.frame) && $0.leaf.frame != box.leaf.frame }
            parent?.children.append(box)
        }
        return boxes.first ?? Box(DisplayLeaf(frame: CGRect(origin: .zero, size: .zero), kind: .color(.clear)))
    }

    private static func encloses(_ outer: CGRect, _ inner: CGRect) -> Bool {
        let tolerance: CGFloat = 0.5
        return outer.minX - tolerance <= inner.minX && outer.minY - tolerance <= inner.minY
            && outer.maxX + tolerance >= inner.maxX && outer.maxY + tolerance >= inner.maxY
    }

    private static func emit(_ box: Box, host: UIView) -> FigmaNode {
        let frame = box.leaf.frame
        if box.children.isEmpty {
            switch box.leaf.kind {
            case .text(let string, let font, let color, let underline):
                return FigmaNode(
                    tag: "text", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                    font: figmaFont(font, color: color, underline: underline),
                    texts: [FigmaText(text: string, x: frame.minX, y: frame.minY, w: frame.width, h: frame.height)],
                    children: []
                )
            case .rasterizable:
                return FigmaNode(
                    tag: "image", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                    image: box.leaf.image, children: []
                )
            case .roundedRect(let radius, let color):
                return filledRect(frame, radius: radius, color: color)
            case .color(let color):
                return filledRect(frame, radius: nil, color: color)
            case .transparent, .unknown:
                return filledRect(frame, radius: nil, color: nil)
            }
        }
        // A container: its own fill/radius (a pill or card) plus its children laid out.
        let orderedChildren = orderedForLayout(box.children)
        let childNodes = orderedChildren.map { emit($0, host: host) }
        let layout = inferLayout(orderedChildren.map(\.leaf.frame), in: frame)
        let fill = fillColor(box.leaf.kind)
        let token = fill.flatMap(tokenName(for:))
        return FigmaNode(
            tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: fill.map(RGBA.init), fillToken: token,
            radius: cornerRadius(box.leaf.kind).map(Double.init),
            name: layout.axis == .row ? "Row" : "Column",
            layout: FigmaLayout(layout), ordered: true, children: childNodes
        )
    }

    private static func filledRect(_ frame: CGRect, radius: CGFloat?, color: UIColor?) -> FigmaNode {
        FigmaNode(
            tag: "shape", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: color.map(RGBA.init), fillToken: color.flatMap(tokenName(for:)),
            radius: radius.map(Double.init), children: []
        )
    }

    // MARK: content-kind accessors

    private static func fillColor(_ kind: DisplayLeaf.Kind) -> UIColor? {
        switch kind {
        case .roundedRect(_, let color): return color
        case .color(let color): return color
        default: return nil
        }
    }
    private static func cornerRadius(_ kind: DisplayLeaf.Kind) -> CGFloat? {
        if case .roundedRect(let radius, _) = kind { return radius }
        return nil
    }

    // MARK: layout inference

    private static func orderedForLayout(_ children: [Box]) -> [Box] {
        children.sorted {
            abs($0.leaf.frame.minY - $1.leaf.frame.minY) > 4
                ? $0.leaf.frame.minY < $1.leaf.frame.minY
                : $0.leaf.frame.minX < $1.leaf.frame.minX
        }
    }

    private static func inferLayout(_ frames: [CGRect], in parent: CGRect) -> PinCaptureLayout {
        guard frames.count > 1 else {
            return PinCaptureLayout(axis: .column, spacing: 0, padding: padding(parent, frames), alignment: .center)
        }
        let byY = frames.sorted { $0.minY < $1.minY }
        let stackedVertically = zip(byY, byY.dropFirst()).allSatisfy { $1.minY >= $0.maxY - 1 }
        let axis: PinCaptureLayout.Axis = stackedVertically ? .column : .row
        let ordered = axis == .column ? byY : frames.sorted { $0.minX < $1.minX }
        let gaps = zip(ordered, ordered.dropFirst()).map { axis == .column ? $1.minY - $0.maxY : $1.minX - $0.maxX }
        let spacing = gaps.filter { $0 >= 0 }.min() ?? 0
        return PinCaptureLayout(
            axis: axis, spacing: max(spacing, 0), padding: padding(parent, frames),
            alignment: crossAlignment(ordered, in: parent, axis: axis)
        )
    }

    private static func padding(_ parent: CGRect, _ children: [CGRect]) -> EdgeInsets {
        guard let union = children.reduce(nil, unite) else { return EdgeInsets() }
        return EdgeInsets(
            top: max(union.minY - parent.minY, 0), leading: max(union.minX - parent.minX, 0),
            bottom: max(parent.maxY - union.maxY, 0), trailing: max(parent.maxX - union.maxX, 0)
        )
    }

    private static func crossAlignment(_ frames: [CGRect], in parent: CGRect, axis: PinCaptureLayout.Axis) -> PinCaptureLayout.CrossAxis {
        // Compare each child's cross-axis center to the children's shared box; leading if flush-start.
        guard let union = frames.reduce(nil, unite) else { return .center }
        if axis == .column {
            let centered = frames.allSatisfy { abs(($0.midX) - union.midX) < 2 }
            return centered ? .center : .leading
        }
        let centered = frames.allSatisfy { abs(($0.midY) - union.midY) < 2 }
        return centered ? .center : .leading
    }

    private static func unite(_ accumulated: CGRect?, _ next: CGRect) -> CGRect {
        accumulated.map { $0.union(next) } ?? next
    }

    // MARK: content decode → IR

    private static func figmaFont(_ font: UIFont?, color: UIColor?, underline: Bool) -> FigmaFont {
        FigmaFont(
            family: "SF Pro Rounded", size: Double(font?.pointSize ?? 17), weight: cssWeight(font),
            color: color.map(RGBA.init) ?? RGBA(r: 0, g: 0, b: 0, a: 1),
            colorToken: color.flatMap(tokenName(for:)), style: nil, underline: underline
        )
    }

    private static func cssWeight(_ font: UIFont?) -> Int {
        guard let font,
              let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any],
              let weight = traits[.weight] as? CGFloat else { return 400 }
        switch weight {
        case ..<(-0.4): return 300
        case ..<0.1: return 400
        case ..<0.27: return 500
        case ..<0.4: return 600
        case ..<0.6: return 700
        default: return 800
        }
    }

    // MARK: tokens

    private static let colorTokens: [FigmaToken] = PinColorToken.allCases.map {
        FigmaToken(name: $0.rawValue, type: "color", value: RGBA($0.color, style: .light), dark: RGBA($0.color, style: .dark))
    }

    private static func tokenName(for color: UIColor) -> String? {
        let target = RGBA(color)
        for token in PinColorToken.allCases {
            let candidate = RGBA(token.color, style: .light)
            if abs(candidate.r - target.r) < 0.02, abs(candidate.g - target.g) < 0.02,
               abs(candidate.b - target.b) < 0.02, abs(candidate.a - target.a) < 0.05 {
                return token.rawValue
            }
        }
        return nil
    }

}
