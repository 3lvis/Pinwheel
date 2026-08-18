import SwiftUI
import UIKit

// Turns DisplayList leaves into the Figma IR, inferring layout from the frames SwiftUI computed.
@MainActor
public enum PinDisplayListCapture {
    /// Set `liveControlsOnScreen` only when `view` is on-screen: off-screen, the key window cropped for UIKit controls is a foreign surface whose pixels would land on the controls.
    public static func document<Content: SwiftUI.View>(_ view: Content, name: String, size: CGSize, screenHeight: CGFloat, liveControlsOnScreen: Bool = false) -> FigmaDocument? {
        // On a dark sim the "light" pass otherwise renders dark, so a token RGBA-matches the wrong (dark) value and imports invisible.
        guard let light = singleDocument(view.environment(\.colorScheme, .light), name: name, size: size, screenHeight: screenHeight, liveControlsOnScreen: liveControlsOnScreen) else { return nil }
        // Rasterized nodes (SF Symbols, spinners) bake their tint into pixels, so render again forced-dark and graft the dark pixels on by position (identical structure zips).
        guard let dark = singleDocument(view.environment(\.colorScheme, .dark), name: name, size: size, screenHeight: screenHeight, liveControlsOnScreen: liveControlsOnScreen) else { return light }
        return FigmaDocument(width: light.width, height: light.height, root: withDarkVariants(light.root, dark.root),
                             tokens: light.tokens, textStyles: light.textStyles)
    }

    /// Capture from an on-screen host: the live render is complete (every UIKit control has painted, nothing drops), cropped in the sim's current appearance.
    public static func document<Content: SwiftUI.View>(_ view: Content, name: String, size: CGSize, screenHeight: CGFloat, liveHost: UIView) -> FigmaDocument? {
        // `drawHierarchy` on the key window paints controls in the sim's current appearance; a plain layer render returns stale pixels.
        guard let leaves = PinDisplayList.leaves(fromHost: liveHost, liveControlsOnScreen: true) else { return nil }
        return build(view, name: name, leaves: leaves, host: liveHost, size: size, screenHeight: screenHeight)
    }

    // fillDark is the fallback for a fill no token names (e.g. a List separator's Apple color, which stayed light on dark without it); a tokenized fill adapts via the token.
    private static func withDarkVariants(_ light: FigmaNode, _ dark: FigmaNode?) -> FigmaNode {
        var node = light
        if node.image != nil { node.imageDark = dark?.image }
        if node.fill != nil { node.fillDark = dark?.fill }
        let darkChildren = dark?.children ?? []
        node.children = light.children.enumerated().map { index, child in
            withDarkVariants(child, index < darkChildren.count ? darkChildren[index] : nil)
        }
        return node
    }

    private static func singleDocument<Content: SwiftUI.View>(_ view: Content, name: String, size: CGSize, screenHeight: CGFloat, liveControlsOnScreen: Bool) -> FigmaDocument? {
        guard let (leaves, host, window) = PinDisplayList.read(view, size: size, liveControlsOnScreen: liveControlsOnScreen) else { return nil }
        return withExtendedLifetime(window) { build(view, name: name, leaves: leaves, host: host, size: size, screenHeight: screenHeight) }
    }

    private static func build<Content: SwiftUI.View>(_ view: Content, name: String, leaves: [DisplayLeaf], host: UIView, size: CGSize, screenHeight: CGFloat) -> FigmaDocument? {
        // The screen fill spans the oversized host; trim it to the content so the root matches the real screen.
        let contentBottom = (leaves.map { $0.frame.maxY }.filter { $0 < size.height - 1 }.max() ?? size.height)
        let trimmed = leaves.map { leaf in
            leaf.frame.height >= size.height - 1
                ? DisplayLeaf(frame: CGRect(x: leaf.frame.minX, y: leaf.frame.minY, width: leaf.frame.width, height: contentBottom + 24), kind: leaf.kind)
                : leaf
        }
        let root = containmentTree(trimmed)
        let components = orderedComponents(root)
        let screenFill = fillColor(root.leaf.kind)

        // Reflection supplies the semantic layout tree (native VStack/HStack leave no drawable to group by);
        // zip it with the rendered leaves. Prefer the grouped components (their count usually matches the
        // reflected leaves); fall back to the fully-flattened leaves when reflection is richer than
        // containment's grouping — a plain image+text row collapses to one component, but reflection sees its
        // parts, and the flattened leaves (image, title, subtitle) line back up. Fall through to containment
        // only when neither count agrees.
        if let structure = PinViewReflector.reflect(view) {
            let reflectedLeaves = leafCount(structure)
            let deepLeaves = components.flatMap(allLeaves)
            let pool: [Box]? = reflectedLeaves == components.count ? components
                : (reflectedLeaves == deepLeaves.count && hasMixedRow(structure) ? deepLeaves : nil)
            if var pool {
                let backgrounds = collectBackgrounds(root)
                let content = emitStructure(structure, host: host, backgrounds: backgrounds) { text in
                    let matched = pool.firstIndex { componentText($0) == text } ?? (pool.isEmpty ? nil : 0)
                    return matched.map { pool.remove(at: $0) }
                }
                if let content {
                    var rootNode = screen(content, width: size.width, fill: screenFill, components: components, canvasHeight: size.height, oneScreen: screenHeight, safeAreaTop: host.safeAreaInsets.top)
                    rootNode.name = name
                    return FigmaDocument(width: size.width, height: rootNode.h, root: componentizeRepeatedChildren(stripDuplicateNestedBackground(rootNode)), tokens: colorTokens + PinFloatTokens.tokens, textStyles: textStyles)
                }
            }
        }

        var rootNode = emit(root, host: host)
        // PinStateView reflects as one leaf but renders several, so it fell to containment; re-center it (a no-op for top-anchored content, which isn't centered-in-canvas).
        let minY = components.map { $0.leaf.frame.minY }.min() ?? 0
        let maxY = components.map { $0.leaf.frame.maxY }.max() ?? 0
        if abs((minY + maxY) / 2 - size.height / 2) < screenHeight / 4, (maxY - minY) < screenHeight {
            rootNode = screen(rootNode, width: size.width, fill: screenFill, components: components, canvasHeight: size.height, oneScreen: screenHeight, safeAreaTop: host.safeAreaInsets.top)
        }
        rootNode.name = name
        return FigmaDocument(width: size.width, height: rootNode.h, root: componentizeRepeatedChildren(stripDuplicateNestedBackground(rootNode)), tokens: colorTokens + PinFloatTokens.tokens, textStyles: textStyles)
    }

    // Sibling frames with an identical structural signature (everything but text content and per-instance
    // fill) are one template: stamp them a shared key so the plugin imports the first as a Figma component
    // and the rest as instances. There's no cell class as on the UIKit side, so the signature carries the
    // discrimination — it includes size, so a grouping is faithful (an instance overrides only text/fill,
    // which is all that differs). Subtrees with an image leaf are excluded — a crop can't be reproduced.
    // A card's fill matches every container that wraps the same text set, so a sibling that carries no text
    // (a thumbnail) leaves the card frame and its inner content frame indistinguishable and both claim the
    // background — doubling the fill and the padding. Strip the inner copy: a child frame sharing its
    // parent's fill token and radius duplicated it, so the outer frame owns the background alone. Only a
    // *lone* matching child is a duplicate wrapper; many same-fill siblings are stacked rows (a PinList's
    // primaryBackground rows on a primaryBackground screen), which legitimately carry the fill and insets.
    static func stripDuplicateNestedBackground(_ node: FigmaNode) -> FigmaNode {
        var node = node
        node.children = node.children.map(stripDuplicateNestedBackground)
        guard let token = node.fillToken else { return node }
        let matches = node.children.filter { $0.tag == "frame" && $0.fillToken == token && $0.radiusToken == node.radiusToken }
        guard matches.count == 1 else { return node }
        node.children = node.children.map { child in
            guard child.tag == "frame", child.fillToken == token, child.radiusToken == node.radiusToken else { return child }
            var child = child
            child.fill = nil
            child.fillToken = nil
            child.fillDark = nil
            child.radius = nil
            child.radiusToken = nil
            if var layout = child.layout {
                layout.pad = [0, 0, 0, 0]
                layout.padTokens = [nil, nil, nil, nil]
                child.layout = layout
            }
            return child
        }
        return node
    }

    static func componentizeRepeatedChildren(_ node: FigmaNode) -> FigmaNode {
        var node = node
        node.children = node.children.map(componentizeRepeatedChildren)
        let signatures = node.children.map { child -> String? in
            (child.tag == "frame" && child.component == nil) ? signature(child) : nil
        }
        var counts: [String: Int] = [:]
        for case let signature? in signatures { counts[signature, default: 0] += 1 }
        let originalChildren = node.children

        // The master of a component must carry every optional layer: a Figma instance can hide a layer but
        // not add one. So a subset row joins by gaining hidden placeholders, and a superset row is promoted
        // to master (the existing members then gaining the placeholders instead).
        var clusterKeyBySignature: [String: Int] = [:]
        var clusterMaster: [Int] = []
        var clusterMembers: [[Int]] = []
        var clusterKey: [String] = []
        for (index, signature) in signatures.enumerated() {
            guard let signature, counts[signature, default: 0] >= 2 else { continue }
            if let cluster = clusterKeyBySignature[signature] {
                clusterMembers[cluster].append(index)
            } else {
                clusterKeyBySignature[signature] = clusterMaster.count
                clusterMaster.append(index)
                clusterMembers.append([index])
                clusterKey.append(signature)
            }
        }
        for index in originalChildren.indices {
            guard originalChildren[index].tag == "frame", originalChildren[index].component == nil else { continue }
            if let signature = signatures[index], counts[signature, default: 0] >= 2 { continue }
            for cluster in clusterMaster.indices {
                let master = originalChildren[clusterMaster[cluster]]
                if variantAlign(master: master, into: originalChildren[index]) != nil {
                    clusterMembers[cluster].append(index)
                    break
                }
                if variantAlign(master: originalChildren[index], into: master) != nil {
                    clusterMaster[cluster] = index
                    clusterMembers[cluster].append(index)
                    break
                }
            }
        }

        var assignment: [Int: (key: String, node: FigmaNode)] = [:]
        for cluster in clusterMaster.indices where clusterMembers[cluster].count >= 2 {
            let master = originalChildren[clusterMaster[cluster]]
            for member in clusterMembers[cluster] {
                if let normalized = variantAlign(master: master, into: originalChildren[member]) {
                    assignment[member] = (clusterKey[cluster], normalized)
                }
            }
        }
        node.children = originalChildren.enumerated().map { index, child in
            guard let (key, normalized) = assignment[index] else { return child }
            var componentized = normalized
            componentized.component = key
            return componentized
        }
        return node
    }

    // Normalize a subset frame to a master's structure so it can be an instance of the same component: align
    // children in order, inserting a hidden copy of any master child the subset lacks (an optional layer).
    // Returns nil when the subset carries a child the master doesn't — then it isn't a variant of this master.
    // A container matches by layout axis, not size (its size legitimately shrinks when it drops an optional
    // child); a leaf matches by role (text style / same tag), since per-instance content is overridden later.
    private static func variantAlign(master: FigmaNode, into subset: FigmaNode) -> FigmaNode? {
        guard master.tag == subset.tag else { return nil }
        switch master.tag {
        case "text": return master.font?.style == subset.font?.style ? subset : nil
        case "image", "spacer": return subset.children.isEmpty ? subset : nil
        default: break
        }
        guard master.layout?.mode == subset.layout?.mode else { return nil }
        var aligned: [FigmaNode] = []
        var index = 0
        for masterChild in master.children {
            if index < subset.children.count, let child = variantAlign(master: masterChild, into: subset.children[index]) {
                aligned.append(child)
                index += 1
            } else {
                var placeholder = masterChild
                placeholder.hidden = true
                aligned.append(placeholder)
            }
        }
        guard index == subset.children.count else { return nil }
        var normalized = subset
        normalized.children = aligned
        return normalized
    }

    private static func signature(_ node: FigmaNode) -> String {
        if node.tag == "text" { return "T:\(node.font?.style ?? "-"):\(node.textAlign ?? "-")" }
        // Bucket size to ~16pt so content-driven width jitter (a longer price, a wider label) doesn't split
        // one template, while a real size difference (a 120 vs 240 card) still lands in distinct buckets.
        func bucket(_ value: Double) -> Int { Int((value / 16).rounded()) }
        if node.tag == "image" { return "IMG:w\(bucket(node.w)):h\(bucket(node.h))" }
        // A chip (a frame hugging a single text — a status pill) sizes to its overridable text, so its width
        // varies per instance; omit its size so a short "Bonus" and a long "Not delivered" share a template.
        // Any other frame keeps size-keying, so genuinely different-sized cards stay distinct.
        let isChip = node.children.count == 1 && node.children.first?.tag == "text"
        var parts = [isChip ? node.tag : "\(node.tag):w\(bucket(node.w)):h\(bucket(node.h))"]
        // Only the axis is stable — justify/align/gap are inferred from rendered geometry and wobble with
        // text width across otherwise-identical cards, so they'd falsely split one template. Instances
        // inherit the master's layout regardless.
        if let layout = node.layout { parts.append("L\(layout.mode)") }
        // Fill is keyed by PRESENCE, not colour — a Figma instance can override a fill, so rows differing
        // only by a chip's colour (bonus blue vs warning neutral) group and the plugin overrides per instance.
        parts.append("F:\(node.fill != nil || node.fillToken != nil ? "#" : "-")")
        parts.append("R:\(node.radiusToken ?? (node.radius != nil ? "#" : "-"))")
        parts.append("[\(node.children.map(signature).joined(separator: ","))]")
        return parts.joined(separator: "|")
    }

    private static func hasMixedRow(_ node: ReflectedNode) -> Bool {
        guard case .container(_, let children) = node else { return false }
        var hasLeaf = false, hasContainer = false
        for child in children {
            if case .leaf = child { hasLeaf = true }
            if case .container = child { hasContainer = true }
        }
        return (hasLeaf && hasContainer) || children.contains { hasMixedRow($0) }
    }

    private static func leafCount(_ node: ReflectedNode) -> Int {
        switch node {
        case .leaf: return 1
        case .spacer: return 0
        case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
        }
    }

    private static func orderedComponents(_ box: Box) -> [Box] {
        let leaves = box.children.isEmpty ? [box] : orderedForLayout(box.children).flatMap(flatten)
        return groupOrphanIcons(leaves)
    }

    // Every leaf under a box (fully flattened, unlike `flatten` which stops at a cohesive box-of-leaves) — the
    // tolerant-zip pool, so a row collapsed to one component still offers its image/title/subtitle to reflection.
    private static func allLeaves(_ box: Box) -> [Box] {
        box.children.isEmpty ? [box] : box.children.flatMap(allLeaves)
    }

    private static func flatten(_ box: Box) -> [Box] {
        let groupsOthers = box.children.contains { !$0.children.isEmpty }
        if box.children.isEmpty || !groupsOthers { return [box] }
        return orderedForLayout(box.children).flatMap(flatten)
    }

    // A fill-less (tertiary) button has no pill enclosing its label + icon, so they arrive as adjacent orphan leaves — regroup an icon next to a same-row text.
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
        if case .text(let string, _, _, _, _, _) = box.leaf.kind { return string }
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
            if isButton, node.tag != "frame" { node = bareButtonContainer(node) }
            if fillWidth { node = fillWidthCentered(node) }
            return node
        case .spacer:
            return FigmaNode(tag: "spacer", x: 0, y: 0, w: 0, h: 0, grow: true, children: [])
        case .container(let container, let children):
            let childNodes = children.compactMap { emitStructure($0, host: host, backgrounds: backgrounds, next: next) }
            guard childNodes.contains(where: { $0.grow != true }) else { return nil }
            // Reflection sees a card's filled shape as a transparent container — re-attach its fill/radius/padding by matching the text set it wraps.
            let texts = childNodes.reduce(into: Set<String>()) { $0.formUnion(nodeTexts($1)) }
            let background = backgrounds.first { $0.texts == texts }
            var padding = background?.padding ?? EdgeInsets()
            let fillsWidth = container.axis == .column && container.alignment == .leading
                && padding.trailing > padding.leading + 8
            if fillsWidth { padding.trailing = padding.leading }
            let layout = PinCaptureLayout(
                axis: container.axis, spacing: container.spacing ?? 8,
                padding: padding, alignment: container.alignment, mainAxisAlignment: .leading
            )
            var node = FigmaNode(
                tag: "frame", x: 0, y: 0, w: 0, h: 0,
                fill: background?.fill.map(RGBA.init), fillToken: background?.fill.flatMap(tokenName(for:)),
                radius: background?.radius.map(Double.init),
                radiusToken: radiusTokenName(background?.radius),
                name: container.axis == .row ? "HStack" : "VStack",
                layout: FigmaLayout(layout), ordered: true, children: childNodes
            )
            let propagatesFill = childNodes.contains { $0.grow == true || $0.fillWidth == true }
            if fillsWidth || propagatesFill { node.fillWidth = true }
            if let border = container.border {
                // A bordered control that reflects to a single frame (a stepper: its ± Buttons drop, leaving
                // the value leaf that matches the rendered box) is one bordered pill in code — put the border
                // on that box rather than wrapping it in a second frame, so the capture matches the source.
                if childNodes.count == 1, childNodes[0].tag == "frame" {
                    return bordered(childNodes[0], border)
                }
                return bordered(node, border)
            }
            return node
        }
    }

    static let bareButtonMinWidth: CGFloat = 100

    private static func bareButtonContainer(_ content: FigmaNode) -> FigmaNode {
        let layout = PinCaptureLayout(
            axis: .row, spacing: .spacing2,
            padding: EdgeInsets(top: .spacing3, leading: .spacing4, bottom: .spacing3, trailing: .spacing4),
            alignment: .center, mainAxisAlignment: .center, minWidth: bareButtonMinWidth
        )
        return FigmaNode(
            tag: "frame", x: content.x, y: content.y,
            w: max(content.w + 2 * Double(CGFloat.spacing4), Double(bareButtonMinWidth)),
            h: content.h + 2 * Double(CGFloat.spacing3),
            name: "Pill", layout: FigmaLayout(layout), ordered: true, children: [content]
        )
    }

    // Pin the width-controlling axis to FIXED so the plugin keeps the captured width instead of hugging
    // the frame's content — width is the primary axis for a row, the counter axis for a column.
    private static func fixingWidth(_ node: FigmaNode) -> FigmaNode {
        guard var layout = node.layout else { return node }
        if layout.mode == "row" { layout.primarySizing = "FIXED" } else { layout.counterSizing = "FIXED" }
        var fixed = node
        fixed.layout = layout
        return fixed
    }

    // `.frame(maxWidth: .infinity)` centers the button at its own width rather than stretching it, so wrap it in a parent-filling centering frame.
    private static func fillWidthCentered(_ content: FigmaNode) -> FigmaNode {
        let layout = PinCaptureLayout(axis: .column, spacing: 0, padding: EdgeInsets(), alignment: .center, mainAxisAlignment: .center)
        var wrapper = FigmaNode(tag: "frame", x: content.x, y: content.y, w: 0, h: content.h, name: "Center", layout: FigmaLayout(layout), ordered: true, children: [content])
        wrapper.fillWidth = true
        return wrapper
    }

    private struct Background { let texts: Set<String>; let fill: UIColor?; let radius: CGFloat?; let padding: EdgeInsets }

    private static func collectBackgrounds(_ box: Box) -> [Background] {
        var result: [Background] = []
        func visit(_ box: Box) {
            // A card's fill wraps its content: either a box with nested groups, or a flat box holding 2+
            // children (a simple card — thumbnail + text column, or a title + price line). A single-child
            // fill box is a pill (a SALE chip), captured through its own leaf, so it's not a card background.
            let isCard = box.children.contains { !$0.children.isEmpty } || box.children.count >= 2
            if isCard, let fill = fillColor(box.leaf.kind) {
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
        if case .text(let string, _, _, _, _, _) = box.leaf.kind { texts.insert(string) }
        box.children.forEach { texts.formUnion(boxTexts($0)) }
        return texts
    }

    private static func nodeTexts(_ node: FigmaNode) -> Set<String> {
        var texts = Set(node.texts?.map(\.text) ?? [])
        node.children.forEach { texts.formUnion(nodeTexts($0)) }
        return texts
    }

    private static func bordered(_ node: FigmaNode, _ border: ReflectedBorder) -> FigmaNode {
        var node = node
        let color = UIColor(border.color)
        node.stroke = RGBA(color)
        node.strokeToken = tokenName(for: color)
        node.strokeWidth = Double(border.width)
        // A Capsule border is a full pill; Figma clamps an oversized cornerRadius to half the shorter side,
        // so a large value renders as a pill without needing the frame's measured height.
        if border.isPill { node.radius = 1000 }
        else if border.cornerRadius > 0 {
            node.radius = Double(border.cornerRadius)
            node.radiusToken = radiusTokenName(border.cornerRadius)
        }
        return node
    }

    private static func componentNode(_ box: Box, host: UIView) -> FigmaNode {
        let frame = box.leaf.frame
        if box.children.isEmpty {
            switch box.leaf.kind {
            case .text(let string, let font, let color, let underline, let strikethrough, let alignment):
                return FigmaNode(
                    tag: "text", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                    font: figmaFont(font, color: color, underline: underline, strikethrough: strikethrough),
                    texts: [FigmaText(text: string, x: frame.minX, y: frame.minY, w: frame.width, h: frame.height)],
                    textAlign: textAlignName(alignment),
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
            radiusToken: radiusTokenName(cornerRadius(box.leaf.kind)),
            name: "Pill", layout: FigmaLayout(layout), ordered: true, children: childNodes
        )
    }

    private static func screen(_ content: FigmaNode, width: CGFloat, fill: UIColor?, components: [Box], canvasHeight: CGFloat, oneScreen: CGFloat, safeAreaTop: CGFloat) -> FigmaNode {
        let minY = components.map { $0.leaf.frame.minY }.min() ?? 0
        let maxY = components.map { $0.leaf.frame.maxY }.max() ?? 0
        let minX = components.map { $0.leaf.frame.minX }.min() ?? 0
        let maxX = components.map { $0.leaf.frame.maxX }.max() ?? 0
        let contentHeight = maxY - minY
        // A short content screen can also land near the canvas center, so require content to actually float (start well below the safe area) before centering, else top-anchor it.
        let floatsBelowSafeArea = (minY - safeAreaTop) > oneScreen / 6
        let centeredInCanvas = floatsBelowSafeArea && abs((minY + maxY) / 2 - canvasHeight / 2) < oneScreen / 4 && contentHeight < oneScreen
        let topPad: CGFloat, bottomPad: CGFloat, height: CGFloat
        if centeredInCanvas {
            topPad = (oneScreen - contentHeight) / 2
            bottomPad = topPad
            height = oneScreen
        } else {
            // Subtract the safe area from the captured top Y — the plugin's device frame already draws the status bar, so keeping it would double the top padding.
            topPad = max(minY - safeAreaTop, 0)
            height = max(oneScreen, topPad + contentHeight)
            bottomPad = max(height - topPad - contentHeight, 0)
        }
        var screenNode = content
        screenNode.tag = "screen"
        screenNode.x = 0
        screenNode.y = 0
        screenNode.w = Double(width)
        screenNode.h = Double(height)
        screenNode.fill = fill.map(RGBA.init)
        screenNode.fillToken = fill.flatMap(tokenName(for:))
        if var layout = screenNode.layout {
            layout.pad = [Double(topPad), Double(width) - Double(maxX), Double(bottomPad), Double(minX)]
            layout.padTokens = layout.pad.map(PinFloatTokens.spacingName(for:))
            layout.primarySizing = "FIXED"
            layout.counterSizing = "FIXED"
            screenNode.layout = layout
        }
        return screenNode
    }

    final class Box {
        let leaf: DisplayLeaf
        var children: [Box] = []
        init(_ leaf: DisplayLeaf) { self.leaf = leaf }
        var area: CGFloat { leaf.frame.width * leaf.frame.height }
    }

    // Build a structured node from raw leaves via containment alone. For a consumer's arbitrary content
    // (a raw List cell, whose whole row lives in one CellHostingView DisplayList) there's no SwiftUI value
    // to reflect, so geometry is all we have. A flat row has no leaf enclosing its siblings, so seed a
    // transparent root spanning their union — otherwise containmentTree keeps only the largest leaf.
    static func containmentNode(leaves: [DisplayLeaf], host: UIView) -> FigmaNode? {
        guard let first = leaves.first else { return nil }
        // Strictly larger than the union so it encloses even a lone leaf whose frame equals the union —
        // containmentTree refuses to nest a child sharing the parent's exact frame.
        let bounds = leaves.dropFirst().map(\.frame).reduce(first.frame) { $0.union($1) }.insetBy(dx: -1, dy: -1)
        let rooted = [DisplayLeaf(frame: bounds, kind: .transparent)] + leaves
        return emit(containmentTree(rooted), host: host)
    }

    private static func containmentTree(_ leaves: [DisplayLeaf]) -> Box {
        let parentsBeforeChildren = leaves.map(Box.init).sorted { $0.area > $1.area }
        for (index, box) in parentsBeforeChildren.enumerated() {
            let parent = parentsBeforeChildren[..<index].last { encloses($0.leaf.frame, box.leaf.frame) && $0.leaf.frame != box.leaf.frame }
            parent?.children.append(box)
        }
        return parentsBeforeChildren.first ?? Box(DisplayLeaf(frame: CGRect(origin: .zero, size: .zero), kind: .color(.clear)))
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
            case .text(let string, let font, let color, let underline, let strikethrough, let alignment):
                return FigmaNode(
                    tag: "text", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                    font: figmaFont(font, color: color, underline: underline, strikethrough: strikethrough),
                    texts: [FigmaText(text: string, x: frame.minX, y: frame.minY, w: frame.width, h: frame.height)],
                    textAlign: textAlignName(alignment),
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
        let fill = fillColor(box.leaf.kind)
        let token = fill.flatMap(tokenName(for:))
        // A flat set that inference reads as one row but that stacks in several Y-bands is a vertical list
        // with overlapping rows; emit absolute positions so the plugin doesn't reflow and misplace them.
        // Judge the axis by direct children, not flattened leaves (which drop per-row backgrounds).
        let listLeaves = flattenLeaves(box.children)
        let bands = yBands(listLeaves)
        if bands.count > 1, inferLayout(orderedForLayout(box.children).map(\.leaf.frame), in: frame).axis == .row {
            let rowNodes = bands.map { $0.count == 1 ? emit($0[0], host: host) : absoluteRowGroup($0, host: host) }
            return FigmaNode(
                tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
                fill: fill.map(RGBA.init), fillToken: token,
                radius: cornerRadius(box.leaf.kind).map(Double.init),
                radiusToken: radiusTokenName(cornerRadius(box.leaf.kind)),
                name: "List", children: rowNodes
            )
        }
        let orderedChildren = orderedForLayout(box.children)
        var layout = inferLayout(orderedChildren.map(\.leaf.frame), in: frame)
        let fillsWidth = layout.axis == .column && layout.alignment == .leading
            && layout.padding.trailing > layout.padding.leading + 8
        if fillsWidth {
            layout = PinCaptureLayout(axis: layout.axis, spacing: layout.spacing,
                                      padding: EdgeInsets(top: layout.padding.top, leading: layout.padding.leading,
                                                          bottom: layout.padding.bottom, trailing: layout.padding.leading),
                                      alignment: layout.alignment, mainAxisAlignment: layout.mainAxisAlignment)
        }
        // A leading column pins children left, so a child centered on the axis but inset from the leading edge (a spacing bar sharing the column with a header) gets a full-width centering slot.
        let contentMinX = orderedChildren.map { $0.leaf.frame.minX }.min() ?? frame.minX
        let childNodes = orderedChildren.map { child -> FigmaNode in
            var node = emit(child, host: host)
            // A child that spans the parent's width fills it (the color demo's full-bleed rows); keep that
            // width fixed so the plugin holds it rather than hugging the frame to its content.
            if child.leaf.frame.width >= frame.width - 0.5 { node = fixingWidth(node) }
            guard layout.axis == .column, layout.alignment == .leading else { return node }
            let centeredOnAxis = abs(child.leaf.frame.midX - frame.midX) < 2
            let insetFromLeading = child.leaf.frame.minX - contentMinX > 1
            return (centeredOnAxis && insetFromLeading) ? fillWidthCentered(node) : node
        }
        var node = FigmaNode(
            tag: "frame", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: fill.map(RGBA.init), fillToken: token,
            radius: cornerRadius(box.leaf.kind).map(Double.init),
            radiusToken: radiusTokenName(cornerRadius(box.leaf.kind)),
            name: layout.axis == .row ? "Row" : "Column",
            layout: FigmaLayout(layout), ordered: true, children: childNodes
        )
        if fillsWidth { node.fillWidth = true }
        return node
    }

    private static func flattenLeaves(_ boxes: [Box]) -> [Box] {
        boxes.flatMap { box in
            box.children.isEmpty || fillColor(box.leaf.kind) != nil || cornerRadius(box.leaf.kind) != nil
                ? [box]
                : flattenLeaves(box.children)
        }
    }

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

    private static func absoluteRowGroup(_ band: [Box], host: UIView) -> FigmaNode {
        let union = band.map(\.leaf.frame).reduce(band[0].leaf.frame) { $0.union($1) }
        let children = orderedForLayout(band).map { emit($0, host: host) }
        return FigmaNode(tag: "frame", x: union.minX, y: union.minY, w: union.width, h: union.height, name: "Row", children: children)
    }

    private static func radiusTokenName(_ radius: CGFloat?) -> String? {
        radius.flatMap { PinFloatTokens.radiusName(for: Double($0)) }
    }

    // Left/natural are the plugin's default, so leave them unset; only center/right are emitted.
    static func textAlignName(_ alignment: NSTextAlignment) -> String? {
        switch alignment {
        case .center: return "center"
        case .right: return "right"
        default: return nil
        }
    }

    private static func filledRect(_ frame: CGRect, radius: CGFloat?, color: UIColor?) -> FigmaNode {
        FigmaNode(
            tag: "shape", x: frame.minX, y: frame.minY, w: frame.width, h: frame.height,
            fill: color.map(RGBA.init), fillToken: color.flatMap(tokenName(for:)),
            radius: radius.map(Double.init), radiusToken: radiusTokenName(radius), children: []
        )
    }

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

    static func orderedForLayout(_ children: [Box]) -> [Box] {
        children.sorted {
            abs($0.leaf.frame.midY - $1.leaf.frame.midY) > 4
                ? $0.leaf.frame.midY < $1.leaf.frame.midY
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

    static func figmaFont(_ font: UIFont?, color: UIColor?, underline: Bool, strikethrough: Bool = false) -> FigmaFont {
        FigmaFont(
            family: fontFamily(font), size: Double(font?.pointSize ?? 17), weight: cssWeight(font),
            color: color.map(RGBA.init) ?? RGBA(r: 0, g: 0, b: 0, a: 1),
            colorToken: color.flatMap(textColorToken(for:)),
            style: font.flatMap { PinCaptureTokens.current.textStyleName(for: $0) }, underline: underline,
            strikethrough: strikethrough
        )
    }

    static func fontFamily(_ font: UIFont?) -> String {
        guard let family = font?.familyName, !family.hasPrefix(".") else { return PinCaptureTokens.current.systemFontFamily }
        return family
    }

    private static func textColorToken(for color: UIColor) -> String? {
        PinCaptureTokens.current.colorName(for: color, textRoleOnly: true)
    }

    static var textStyles: [FigmaTextStyle] { PinCaptureTokens.current.figmaTextStyles }

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

    static var colorTokens: [FigmaToken] { PinCaptureTokens.current.figmaColorTokens }

    static func tokenName(for color: UIColor) -> String? {
        PinCaptureTokens.current.colorName(for: color)
    }

}
