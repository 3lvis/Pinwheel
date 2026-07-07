import SwiftUI
import UIKit
import Pinwheel

// Turns the DisplayList leaves into the Figma IR — a nested auto-layout tree — with no capture
// markers in the view. Containment groups leaves (a pill encloses its label/icon; a card encloses
// its buttons); axis/spacing/alignment are inferred from the frames SwiftUI already computed.
@MainActor
public enum PinDisplayListCapture {
    /// Set `liveControlsOnScreen` only when `view` is the on-screen content (a full-screen sweep) — it
    /// lets the capture crop UIKit controls (a switch/date picker) from the live window, which paints
    /// their real state. When the view isn't on screen (a capture-on-view from the catalog), leave it
    /// false: the key window is some other surface, and cropping it would put foreign pixels on the
    /// controls. Off-screen controls then fall back to their (flat) host-layer render.
    public static func document<Content: SwiftUI.View>(_ view: Content, name: String, size: CGSize, screenHeight: CGFloat, liveControlsOnScreen: Bool = false) -> FigmaDocument? {
        guard let (leaves, host, window) = PinDisplayList.read(view, size: size, liveControlsOnScreen: liveControlsOnScreen) else { return nil }
        return withExtendedLifetime(window) { build(view, name: name, leaves: leaves, host: host, size: size, screenHeight: screenHeight) }
    }

    private static func build<Content: SwiftUI.View>(_ view: Content, name: String, leaves: [DisplayLeaf], host: UIView, size: CGSize, screenHeight: CGFloat) -> FigmaDocument? {
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
                var rootNode = screen(content, width: size.width, fill: screenFill, components: components, canvasHeight: size.height, oneScreen: screenHeight)
                rootNode.name = name
                return FigmaDocument(width: size.width, height: rootNode.h, root: rootNode, tokens: colorTokens, textStyles: [])
            }
        }

        var rootNode = emit(root, host: host)
        rootNode.name = name
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
    // component; a shape that groups other components (a card background) is recursed through. The root is
    // the screen container, never itself a component, so flatten its children — otherwise a flat screen
    // (every child a bare leaf, e.g. label-over-control rows) collapses to the single root component and
    // desyncs the reflected leaf count into the containment fallback. A childless root (a lone full-screen
    // label) is itself the sole component.
    private static func orderedComponents(_ box: Box) -> [Box] {
        let leaves = box.children.isEmpty ? [box] : orderedForLayout(box.children).flatMap(flatten)
        return groupOrphanIcons(leaves)
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
    private static func screen(_ content: FigmaNode, width: CGFloat, fill: UIColor?, components: [Box], canvasHeight: CGFloat, oneScreen: CGFloat) -> FigmaNode {
        let minY = components.map { $0.leaf.frame.minY }.min() ?? 0
        let maxY = components.map { $0.leaf.frame.maxY }.max() ?? 0
        let minX = components.map { $0.leaf.frame.minX }.min() ?? 0
        let maxX = components.map { $0.leaf.frame.maxX }.max() ?? 0
        // Content the hosting controller centered in the tall capture canvas (a hugging or fill-centered
        // component sits symmetrically) is a full-screen component — re-center it in one screen so it
        // matches the device, instead of floating in the oversized canvas. Otherwise it's top-anchored:
        // the screen height is the content plus its symmetric top/bottom inset (maxY + minY).
        let centeredInCanvas = abs((minY + maxY) / 2 - canvasHeight / 2) < oneScreen / 4 && (maxY - minY) < oneScreen
        let verticalPad = centeredInCanvas ? (oneScreen - (maxY - minY)) / 2 : minY
        var screenNode = content
        screenNode.tag = "screen"
        screenNode.x = 0
        screenNode.y = 0
        screenNode.w = Double(width)
        screenNode.h = Double(centeredInCanvas ? oneScreen : maxY + minY)
        screenNode.fill = fill.map(RGBA.init)
        screenNode.fillToken = fill.flatMap(tokenName(for:))
        if var layout = screenNode.layout {
            layout.pad = [Double(verticalPad), Double(width) - Double(maxX), Double(verticalPad), Double(minX)]
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
        let fill = fillColor(box.leaf.kind)
        let token = fill.flatMap(tokenName(for:))
        // A flat set of leaves that inference reads as one horizontal row but that stacks in several
        // Y-bands is a vertical list whose rows overlap in Y (icon beside title) — a settings list with
        // no per-row background. Emit it with absolute positions (no layout) so the plugin places each
        // row where it rendered; an auto-layout frame reflows by spacing and misplaces the icons/toggles.
        // Each row is grouped so it's a grabbable unit, also absolute so its title/subtitle stay stacked.
        // Judge the axis by the *direct* children: when they're clean per-row containers that stack
        // vertically (rows with their own background — the Color showcase), that's a column, not a list.
        // Flattening first would drop those backgrounds and misread the side-by-side labels as a row.
        let listLeaves = flattenLeaves(box.children)
        let bands = yBands(listLeaves)
        if bands.count > 1, inferLayout(orderedForLayout(box.children).map(\.leaf.frame), in: frame).axis == .row {
            let rowNodes = bands.map { $0.count == 1 ? emit($0[0], host: host) : absoluteRowGroup($0, host: host) }
            return FigmaNode(
                tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                fill: fill.map(RGBA.init), fillToken: token,
                radius: cornerRadius(box.leaf.kind).map(Double.init),
                name: "List", children: rowNodes
            )
        }
        let orderedChildren = orderedForLayout(box.children)
        let layout = inferLayout(orderedChildren.map(\.leaf.frame), in: frame)
        // A leading column has one cross-alignment, so a child centered on the column's axis but inset
        // from the leading edge — a spacing bar that shrinks toward the middle, sharing the column with a
        // leading header — would be pinned left. Wrap such a child in a full-width centering slot so it
        // stays centered. A leading header (off-axis) and a full-width row (not inset) are left as-is.
        let contentMinX = orderedChildren.map { $0.leaf.frame.minX }.min() ?? frame.minX
        let childNodes = orderedChildren.map { child -> FigmaNode in
            let node = emit(child, host: host)
            guard layout.axis == .column, layout.alignment == .leading else { return node }
            let centeredOnAxis = abs(child.leaf.frame.midX - frame.midX) < 2
            let insetFromLeading = child.leaf.frame.minX - contentMinX > 1
            return (centeredOnAxis && insetFromLeading) ? fillWidthCentered(node) : node
        }
        return FigmaNode(
            tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: fill.map(RGBA.init), fillToken: token,
            radius: cornerRadius(box.leaf.kind).map(Double.init),
            name: layout.axis == .row ? "Row" : "Column",
            layout: FigmaLayout(layout), ordered: true, children: childNodes
        )
    }

    // Flatten to leaf boxes, dropping intermediate containment groups — the list re-bands everything by
    // row, so a pre-grouped two-line row's leaves rejoin their band instead of keeping an auto-layout box.
    private static func flattenLeaves(_ boxes: [Box]) -> [Box] {
        boxes.flatMap { $0.children.isEmpty ? [$0] : flattenLeaves($0.children) }
    }

    // Cluster leaves into vertical bands: each band is the set of leaves that overlap in Y (one visual
    // row). Consecutive bands don't overlap, so a parent laying them out is unambiguously a column.
    private static func yBands(_ children: [Box]) -> [[Box]] {
        let sorted = children.sorted { $0.leaf.frame.minY < $1.leaf.frame.minY }
        var bands: [[Box]] = []
        for box in sorted {
            if !bands.isEmpty, let maxY = bands[bands.count - 1].map({ $0.leaf.frame.maxY }).max(), box.leaf.frame.minY < maxY - 1 {
                bands[bands.count - 1].append(box)
            } else {
                bands.append([box])
            }
        }
        return bands
    }

    // One row of a list: the leaves keep their absolute positions (no auto-layout) so the icon, the
    // title/subtitle stack, and the trailing accessory land where they rendered.
    private static func absoluteRowGroup(_ band: [Box], host: UIView) -> FigmaNode {
        let union = band.map(\.leaf.frame).reduce(band[0].leaf.frame) { $0.union($1) }
        let children = orderedForLayout(band).map { emit($0, host: host) }
        return FigmaNode(tag: "frame", x: union.minX, y: union.minY, w: union.width, h: union.height, name: "Row", children: children)
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
