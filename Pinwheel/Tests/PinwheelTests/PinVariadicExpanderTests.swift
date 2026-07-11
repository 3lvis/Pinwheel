import XCTest
import SwiftUI
@testable import Pinwheel

// Heavy coverage of the private-internals ForEach expander. These are the canary: if a new iOS changes
// SwiftUI's variadic layout or AttributeGraph's ABI, these go RED (and, in production, `isHealthy` flips to
// false and capture falls back to containment instead of misbehaving).
@MainActor
final class PinVariadicExpanderTests: XCTestCase {
    private func leaves(_ node: ReflectedNode?) -> Int {
        switch node {
        case .leaf: return 1
        case .container(_, let children): return children.reduce(0) { $0 + leaves($1) }
        default: return 0
        }
    }

    // THE canary. If this fails on a new OS, the private path broke — fix or accept the containment fallback.
    func testExpanderIsHealthyOnThisOS() {
        XCTAssertTrue(PinVariadicExpander.isHealthy,
                      "the ForEach expander self-test failed — SwiftUI/AttributeGraph internals changed; capture will fall back to containment")
    }

    // A plain ForEach expands to its real row instances, reflectable to correct structure.
    func testExpandsRowsToRealInstances() throws {
        let forEach = ForEach(["Revenue", "Orders", "Users"], id: \.self) { title in
            HStack { PinLabel(title); Spacer(); PinLabel("$1") }
        }
        let rows = try XCTUnwrap(PinVariadicExpander.expand(forEach), "healthy expander returns rows")
        XCTAssertEqual(rows.count, 3)
        XCTAssertTrue(rows.allSatisfy { leaves(PinViewReflector.reflect($0)) == 2 }, "each row: two PinLabels")
    }

    // The decisive property: a runtime conditional resolves per-row (the metatype path could not).
    func testResolvesRuntimeConditionalPerRow() throws {
        let forEach = ForEach(["A", "B"], id: \.self) { name in
            HStack { PinLabel(name); if name == "A" { PinLabel("SALE") }; Spacer() }
        }
        let rows = try XCTUnwrap(PinVariadicExpander.expand(forEach))
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(leaves(PinViewReflector.reflect(rows[0])), 2, "row A keeps the conditional badge")
        XCTAssertEqual(leaves(PinViewReflector.reflect(rows[1])), 1, "row B drops it")
    }

    // A nested 2-D row (the Cart shape) recovers its full structure — the whole point.
    func testExpandsNestedTwoDimensionalRow() throws {
        let forEach = ForEach(["A", "B"], id: \.self) { name in
            HStack {
                RoundedRectangle(cornerRadius: 8).frame(width: 40, height: 40)
                VStack(alignment: .leading) { PinLabel(name); PinLabel("$10") }
                Spacer()
                PinLabel("×1")
            }
        }
        let rows = try XCTUnwrap(PinVariadicExpander.expand(forEach))
        XCTAssertEqual(rows.count, 2)
        // name + $10 + ×1 = 3 text leaves per row (the shape isn't a PinLabel leaf).
        XCTAssertEqual(leaves(PinViewReflector.reflect(rows[0])), 3)
    }

    // A non-view returns nil (never crashes the caller).
    func testNonViewReturnsNil() {
        XCTAssertNil(PinVariadicExpander.expand(42))
    }
}
