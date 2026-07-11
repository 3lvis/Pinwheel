import SwiftUI

// Recovers the SwiftUI layout tree by reflecting the view value over SwiftUI's private, undocumented view internals, which shift between toolchains.

indirect enum ReflectedNode {
    case container(ReflectedContainer, [ReflectedNode])
    case leaf(text: String?, isButton: Bool, fillWidth: Bool)
    case spacer
}

struct ReflectedContainer {
    let axis: PinCaptureLayout.Axis
    let spacing: CGFloat?
    let alignment: PinCaptureLayout.CrossAxis
}

enum PinViewReflector {
    static func reflect(_ view: Any) -> ReflectedNode? {
        walk(view)
    }

    private static func walk(_ value: Any) -> ReflectedNode? {
        let typeName = String(describing: type(of: value))

        // An `if`-without-else yields an Optional view; unwrap `.some`, drop `.none`. Mirror is the only
        // safe unwrap — matching the "Optional" type name and re-walking the same value loops forever.
        if Mirror(reflecting: value).displayStyle == .optional {
            return Mirror(reflecting: value).children.first.flatMap { walk($0.value) }
        }

        if typeName.hasPrefix("VStack") || typeName.hasPrefix("HStack") {
            let axis: PinCaptureLayout.Axis = typeName.hasPrefix("VStack") ? .column : .row
            let (spacing, alignment, content) = stackFields(value)
            let children = content.map { expandedChildren($0) } ?? []
            return .container(ReflectedContainer(axis: axis, spacing: spacing, alignment: alignment), children)
        }
        if isLeaf(typeName) {
            return .leaf(text: leafText(value), isButton: typeName == "PinButton" || typeName.hasPrefix("PinButton<"), fillWidth: false)
        }
        if typeName.hasPrefix("Spacer") {
            return .spacer
        }
        if typeName.hasPrefix("ScrollView") {
            return property(value, "content").flatMap(walk)
        }
        if typeName.hasPrefix("AnyView") {
            return unwrapAnyView(value).flatMap(walk)
        }
        if typeName.hasPrefix("ModifiedContent") {
            let modifier = property(value, "modifier")
            let node = property(value, "content").flatMap(walk)
            if isFillWidthFrame(modifier), case .leaf(let text, let isButton, _) = node {
                return .leaf(text: text, isButton: isButton, fillWidth: true)
            }
            return node
        }
        if typeName.hasPrefix("TupleView") || typeName.hasPrefix("Group") || typeName.hasPrefix("Optional")
            || typeName.hasPrefix("_ConditionalContent") {
            let children = flatten(value).compactMap(walk)
            return children.count == 1 ? children.first : (children.isEmpty ? nil : .container(ReflectedContainer(axis: .column, spacing: nil, alignment: .leading), children))
        }
        // A ForEach not directly inside a stack (e.g. ScrollView { ForEach }) — expand its real rows into a
        // column. Inside a stack, `expandedChildren` splices them as siblings instead.
        if typeName.hasPrefix("ForEach"), let rows = PinVariadicExpander.expand(value) {
            return .container(ReflectedContainer(axis: .column, spacing: nil, alignment: .leading), rows.compactMap(walk))
        }
        if isStructuralContainer(typeName) { return nil }
        if isShape(typeName) {
            return .leaf(text: nil, isButton: false, fillWidth: false)
        }
        if isPrimitive(typeName) { return nil }
        // A SwiftUI primitive's or UIKit-bridge's `.body` traps if reached; skip so capture falls back to containment instead of crashing.
        if value is any UIViewRepresentable || value is any UIViewControllerRepresentable { return nil }
        if let view = value as? any SwiftUI.View {
            if String(reflecting: type(of: value)).hasPrefix("SwiftUI.") { return nil }
            return walk(view.body)
        }
        return nil
    }

    private static let leafTypes = ["PinButton", "PinLabel", "PinList", "PinStateView"]
    private static func isLeaf(_ typeName: String) -> Bool {
        leafTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
    }

    private static func isFillWidthFrame(_ modifier: Any?) -> Bool {
        guard let modifier, String(describing: type(of: modifier)).contains("FlexFrame") else { return false }
        return (Mirror(reflecting: modifier).children.first { $0.label == "maxWidth" }?.value as? CGFloat) == .infinity
    }

    private static func leafText(_ value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        for label in ["title", "text"] {
            if let child = mirror.children.first(where: { $0.label == label })?.value {
                if let string = child as? String { return string }
                if let string = Mirror(reflecting: child).children.first?.value as? String { return string }
            }
        }
        return nil
    }

    private static let primitiveTypes = ["Text", "Image", "Color", "Divider", "EmptyView", "Rectangle",
                                         "RoundedRectangle", "Circle", "Capsule", "Ellipse", "ProgressView",
                                         "Toggle", "Slider", "Label", "Link"]
    private static func isPrimitive(_ typeName: String) -> Bool {
        primitiveTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
    }

    // A standalone shape renders as a fill/stroke box the containment path keeps as a component, so it's a
    // leaf; a filled/stroked shape is a `*ShapeView` (SwiftUI wraps `.fill()`/`.stroke()`). Image is NOT here
    // — the containment path drops SF Symbols, so counting them would desync the reflected leaf total.
    private static func isShape(_ typeName: String) -> Bool {
        if typeName.contains("ShapeView") { return true }
        return shapeTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
    }
    private static let shapeTypes = ["RoundedRectangle", "Rectangle", "Circle", "Capsule", "Ellipse"]
    private static let structuralContainerTypes = ["ForEach", "List", "Section", "LazyVStack", "LazyHStack"]
    private static func isStructuralContainer(_ typeName: String) -> Bool {
        structuralContainerTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
    }

    // A stack's children live behind _VariadicView.Tree { root: _VStackLayout, content: TupleView }.
    private static func stackFields(_ stack: Any) -> (CGFloat?, PinCaptureLayout.CrossAxis, Any?) {
        guard let tree = Mirror(reflecting: stack).children.first?.value else { return (nil, .center, nil) }
        let treeChildren = Mirror(reflecting: tree).children
        let root = treeChildren.first { $0.label == "root" }?.value
        let content = treeChildren.first { $0.label == "content" }?.value
        var spacing: CGFloat?
        var alignment: PinCaptureLayout.CrossAxis = .center
        if let root {
            for field in Mirror(reflecting: root).children {
                if field.label == "spacing", let value = field.value as? CGFloat? { spacing = value }
                if field.label == "alignment" { alignment = crossAxis(field.value) }
            }
        }
        return (spacing, alignment, content)
    }

    // Flatten a stack's content, splicing any ForEach into its real rows (as siblings) so a ForEach-built
    // list reflects as if written inline. If the private expander is unhealthy, the ForEach yields nothing
    // and the whole screen falls to the containment path downstream (count mismatch) — never a crash.
    private static func expandedChildren(_ content: Any) -> [ReflectedNode] {
        flatten(content).flatMap { item -> [ReflectedNode] in
            if String(describing: type(of: item)).hasPrefix("ForEach"), let rows = PinVariadicExpander.expand(item) {
                return rows.compactMap(walk)
            }
            return [item].compactMap(walk)
        }
    }

    private static func flatten(_ content: Any) -> [Any] {
        if String(describing: type(of: content)).hasPrefix("TupleView"),
           let tuple = Mirror(reflecting: content).children.first(where: { $0.label == "value" })?.value {
            return Mirror(reflecting: tuple).children.map(\.value)
        }
        return [content]
    }

    private static func property(_ value: Any, _ label: String) -> Any? {
        let mirror = Mirror(reflecting: value)
        return mirror.children.first { $0.label == label }?.value
    }

    private static func unwrapAnyView(_ value: Any) -> Any? {
        guard let storage = property(value, "storage") else { return nil }
        let mirror = Mirror(reflecting: storage)
        return mirror.children.first { $0.label == "view" }?.value ?? mirror.children.first?.value
    }

    private static func crossAxis(_ alignment: Any) -> PinCaptureLayout.CrossAxis {
        if let horizontal = alignment as? HorizontalAlignment {
            if horizontal == .leading { return .leading }
            if horizontal == .trailing { return .trailing }
        }
        if let vertical = alignment as? VerticalAlignment {
            if vertical == .top { return .leading }
            if vertical == .bottom { return .trailing }
        }
        return .center
    }
}
