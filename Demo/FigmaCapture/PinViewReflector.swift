import SwiftUI
import Pinwheel

// Recovers the SwiftUI layout tree — native VStack/HStack, their spacing/alignment, and the order
// of their leaves — by reflecting the view value with Mirror. SwiftUI won't let us intercept its
// own stacks, so this reads their private internals (_VariadicView.Tree / _VStackLayout). That's
// undocumented and can shift between toolchains (Swift 6 already inserts implicit AnyViews we unwrap
// here); the quirks are contained to this file so a break is one place to fix.

indirect enum ReflectedNode {
    case container(ReflectedContainer, [ReflectedNode])
    case leaf
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

        if typeName.hasPrefix("VStack") || typeName.hasPrefix("HStack") {
            let axis: PinCaptureLayout.Axis = typeName.hasPrefix("VStack") ? .column : .row
            let (spacing, alignment, content) = stackFields(value)
            let children = content.map { flatten($0).compactMap(walk) } ?? []
            return .container(ReflectedContainer(axis: axis, spacing: spacing, alignment: alignment), children)
        }
        // Exact match (allowing a generic parameter) — a prefix would misread PinButtonLayoutDemo,
        // a custom composite, as a PinButton leaf and stop there.
        if isLeaf(typeName) {
            return .leaf
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
            // The modifier (padding/background/frame) is layout we don't model here; walk the content.
            return property(value, "content").flatMap(walk)
        }
        if typeName.hasPrefix("TupleView") || typeName.hasPrefix("Group") || typeName.hasPrefix("Optional")
            || typeName.hasPrefix("_ConditionalContent") {
            // A bare group of views with no stack of its own — hand its children to the parent by
            // returning the first meaningful node, or nothing.
            let children = flatten(value).compactMap(walk)
            return children.count == 1 ? children.first : (children.isEmpty ? nil : .container(ReflectedContainer(axis: .column, spacing: nil, alignment: .leading), children))
        }
        // A raw SwiftUI primitive emits no capture descriptor, so it's not a leaf (counting it would
        // desync the leaf-to-descriptor zip) and its `body` traps — skip it.
        if isPrimitive(typeName) { return nil }
        // Any other view is a custom composite: recurse into its body. `any View` lets us reach
        // `.body` on a value we only hold as `Any`.
        if let view = value as? any SwiftUI.View { return walk(view.body) }
        return nil
    }

    // Pinwheel components that manage their own capture; reflection stops here rather than recursing
    // into their body. PinButton/PinLabel emit one top-level node each (clean 1:1 zip); PinList/
    // PinStateView emit many, which the engine's leaf-count guard catches to fall back to flat.
    private static let leafTypes = ["PinButton", "PinLabel", "PinList", "PinStateView"]
    private static func isLeaf(_ typeName: String) -> Bool {
        leafTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
    }

    // Raw SwiftUI primitives — no descriptor, and their `body` traps, so skip rather than recurse.
    private static let primitiveTypes = ["Text", "Image", "Color", "Divider", "EmptyView", "Rectangle",
                                         "RoundedRectangle", "Circle", "Capsule", "Ellipse", "ProgressView",
                                         "Toggle", "Slider", "Label", "Link"]
    private static func isPrimitive(_ typeName: String) -> Bool {
        primitiveTypes.contains { typeName == $0 || typeName.hasPrefix($0 + "<") }
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
