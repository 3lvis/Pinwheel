import SwiftUI
import UIKit
import Darwin

// Expands a `ForEach` (which reflects to nothing — its content is an uncallable closure) into its real row
// view *instances*, by driving SwiftUI's private variadic machinery and dereferencing each row's node out
// of the AttributeGraph. Reads content from the resolved instances, so runtime conditionals (`if onSale`)
// resolve per-row — impossible from the static type alone.
//
// Every piece here is private, undocumented SwiftUI/AttributeGraph internals pinned to a toolchain. It is
// therefore gated behind `isHealthy`, a cached self-test that expands a known fixture and checks the
// recovered structure; if a new OS changes the ABI/layout, the probe fails and capture falls back to the
// containment path instead of misbehaving. `PinVariadicExpanderTests` asserts the probe + each step so a
// breaking OS turns the suite red in development before it ships.
@MainActor
enum PinVariadicExpander {
    // AGGraphGetValue(attribute: UInt32, options: UInt32, type: metadata) -> AGValue{value: void*, changed}.
    // The 16-byte result returns in x0/x1 (arm64); we only need x0, so model it as the pointer. Resolved at
    // runtime (AttributeGraph is already loaded by SwiftUI) so we never link the private framework.
    private typealias GetValueFn = @convention(c) (UInt32, UInt32, UnsafeRawPointer) -> UnsafeMutableRawPointer?
    private static let getValue: GetValueFn? = {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "AGGraphGetValue") else { return nil }
        return unsafeBitCast(symbol, to: GetValueFn.self)
    }()

    /// The row view instances of a `ForEach` (or any variadic content), or nil when the private path is
    /// unavailable/unhealthy — the caller then falls back to containment.
    static func expand(_ view: Any) -> [Any]? {
        guard isHealthy, let anyView = view as? any SwiftUI.View else { return nil }
        return rawExpand(anyView)
    }

    /// Cached capability probe: only trust the deref if it recovers a known fixture's structure exactly.
    static let isHealthy: Bool = runSelfTest()

    // MARK: Expansion

    private final class Sink {
        var rows: [Any] = []
        var failed = false
    }

    private struct Root: _VariadicView.MultiViewRoot {
        let sink: Sink
        func body(children: _VariadicView.Children) -> some SwiftUI.View {
            for element in children {
                guard let (attribute, type) = attributeAndType(element),
                      let pointer = getValue?(attribute, 0, unsafeBitCast(type, to: UnsafeRawPointer.self)) else {
                    sink.failed = true
                    break
                }
                sink.rows.append(loadValue(UnsafeRawPointer(pointer), as: type))
            }
            // Return the children so SwiftUI actually resolves the list (returning EmptyView short-circuits).
            return children
        }
    }

    private static func rawExpand(_ view: any SwiftUI.View) -> [Any]? {
        guard getValue != nil else { return nil }
        func host<V: SwiftUI.View>(_ content: V) -> [Any]? {
            let sink = Sink()
            let controller = UIHostingController(rootView: _VariadicView.Tree(Root(sink: sink)) { content })
            controller.view.frame = CGRect(x: 0, y: 0, width: 402, height: 1200)
            let window = UIWindow(frame: controller.view.frame)
            window.rootViewController = controller
            window.isHidden = false
            controller.view.layoutIfNeeded()
            return withExtendedLifetime(window) { sink.failed ? nil : sink.rows }
        }
        return _openExistential(view, do: host)
    }

    // MARK: Graph navigation

    // A row's node carries `view: AGWeakAttribute` (id in `_details.identifier.rawValue`) and `viewType`
    // (the row's type metatype). Hunt for that pair inside the element.
    private static func attributeAndType(_ value: Any, _ depth: Int = 0) -> (UInt32, Any.Type)? {
        guard depth < 12 else { return nil }
        let mirror = Mirror(reflecting: value)
        if let weak = mirror.children.first(where: { $0.label == "view" })?.value,
           String(describing: type(of: weak)) == "AGWeakAttribute",
           let type = mirror.children.first(where: { $0.label == "viewType" })?.value as? Any.Type,
           let details = child(weak, "_details"),
           let identifier = child(details, "identifier"),
           let raw = child(identifier, "rawValue") as? UInt32 {
            return (raw, type)
        }
        for element in mirror.children {
            if let found = attributeAndType(element.value, depth + 1) { return found }
        }
        return nil
    }

    private static func child(_ value: Any, _ label: String) -> Any? {
        Mirror(reflecting: value).children.first { $0.label == label }?.value
    }

    // Load a value of a dynamically-known type off a raw pointer into `Any` (recover the type generically).
    private static func loadValue(_ pointer: UnsafeRawPointer, as type: Any.Type) -> Any {
        func project<T>(_ t: T.Type) -> Any { pointer.load(as: T.self) }
        return _openExistential(type, do: project)
    }

    // MARK: Self-test

    private struct ProbeRow: SwiftUI.View {
        let title: String
        let extra: Bool
        var body: some SwiftUI.View {
            HStack { PinLabel(title); if extra { PinLabel("extra") } }
        }
    }

    private static func runSelfTest() -> Bool {
        guard getValue != nil else { return false }
        // Two rows, one with a conditional child — verifies expansion, deref, load, and per-row conditional
        // resolution all at once. A layout/ABI change breaks the recovered structure and trips this.
        let probe = ForEach([true, false], id: \.self) { flag in ProbeRow(title: "row", extra: flag) }
        guard let rows = rawExpand(probe), rows.count == 2 else { return false }
        func leafCount(_ node: ReflectedNode?) -> Int {
            switch node {
            case .leaf: return 1
            case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
            default: return 0
            }
        }
        // Row 0 (extra: true) → 2 labels; row 1 (extra: false) → 1 label. Both must reflect to real HStacks.
        return leafCount(PinViewReflector.reflect(rows[0])) == 2 && leafCount(PinViewReflector.reflect(rows[1])) == 1
    }
}
