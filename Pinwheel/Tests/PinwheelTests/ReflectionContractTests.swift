import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class ReflectionContractTests: XCTestCase {
    private struct CustomComposite: SwiftUI.View {
        var body: some SwiftUI.View { PinLabel("inner body") }
    }

    private struct PinButtonDemo: SwiftUI.View {
        var body: some SwiftUI.View { PinLabel("demo body") }
    }

    @ViewBuilder private func twoLabels() -> some SwiftUI.View {
        PinLabel("First")
        PinLabel("Second")
    }

    @ViewBuilder private func labelBesideNilChild() -> some SwiftUI.View {
        PinLabel("Solo")
        Color.red
    }

    private func leafCount(_ node: ReflectedNode?) -> Int {
        guard let node else { return 0 }
        switch node {
        case .leaf: return 1
        case .spacer: return 0
        case .container(_, let children): return children.reduce(0) { $0 + leafCount($1) }
        }
    }

    func testPinButtonReflectsToOneButtonLeafCarryingItsTitle() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(PinButton("Card") {}))
        guard case .leaf(let text, let isButton, let fillWidth) = node else {
            return XCTFail("a PinButton must reflect as a single leaf, not recurse into its body")
        }
        XCTAssertEqual(text, "Card", "the button leaf carries its title as text")
        XCTAssertTrue(isButton, "a PinButton leaf is flagged as a button")
        XCTAssertFalse(fillWidth, "an unframed button does not fill width")
        XCTAssertEqual(leafCount(node), 1, "a PinButton is exactly one leaf")
    }

    func testPinLabelReflectsToOneNonButtonLeafCarryingItsText() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(PinLabel("Payment method")))
        guard case .leaf(let text, let isButton, let fillWidth) = node else {
            return XCTFail("a PinLabel must reflect as a single leaf, not recurse into its body")
        }
        XCTAssertEqual(text, "Payment method", "the label leaf carries its text")
        XCTAssertFalse(isButton, "a PinLabel leaf is not a button")
        XCTAssertFalse(fillWidth, "an unframed label does not fill width")
        XCTAssertEqual(leafCount(node), 1, "a PinLabel is exactly one leaf")
    }

    func testRawSwiftUIPrimitiveReflectsNil() {
        XCTAssertNil(PinViewReflector.reflect(Picker("choice", selection: .constant(0)) { Text("A").tag(0) }),
                     "a raw SwiftUI Picker is past the String(reflecting:).hasPrefix(\"SwiftUI.\") boundary, so it reflects nil")
        XCTAssertNil(PinViewReflector.reflect(Stepper("Count", onIncrement: {}, onDecrement: {})),
                     "a raw SwiftUI Stepper reflects nil for the same reason — capture falls back to containment")
    }

    func testCustomCompositeRecursesIntoItsBody() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(CustomComposite()),
                                 "a non-SwiftUI composite must recurse into its body rather than reflect nil")
        guard case .leaf(let text, _, _) = node else {
            return XCTFail("the composite's body is a single PinLabel leaf")
        }
        XCTAssertEqual(text, "inner body", "reflect walked into the composite's body and captured its label")
    }

    func testCompositeNamedLikeALeafRecursesRatherThanCapturingAsThatLeaf() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(PinButtonDemo()),
                                 "a composite whose name starts with a leaf name must not be captured as that leaf")
        guard case .leaf(let text, let isButton, _) = node else {
            return XCTFail("PinButtonDemo's body reflects to its inner label leaf")
        }
        XCTAssertFalse(isButton, "PinButtonDemo is not a PinButton — the leaf test is exact-match, not prefix")
        XCTAssertEqual(text, "demo body", "reflect walked into PinButtonDemo's body instead of treating it as a button")
    }

    func testFillWidthFrameFlipsTheLeafFillWidth() throws {
        let framed = try XCTUnwrap(PinViewReflector.reflect(PinButton("Continue") {}.frame(maxWidth: .infinity)))
        guard case .leaf(_, let framedIsButton, let framedFillWidth) = framed else {
            return XCTFail("a framed button is still a single leaf")
        }
        XCTAssertTrue(framedFillWidth, ".frame(maxWidth: .infinity) sets fillWidth true on the wrapped leaf")
        XCTAssertTrue(framedIsButton, "the button flag survives the frame modifier")

        let bare = try XCTUnwrap(PinViewReflector.reflect(PinButton("Continue") {}))
        guard case .leaf(_, _, let bareFillWidth) = bare else {
            return XCTFail("an unframed button is a single leaf")
        }
        XCTAssertFalse(bareFillWidth, "without the fill-width frame, fillWidth is false")
    }

    func testTupleViewWithMultipleChildrenReflectsToAContainer() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(twoLabels()))
        guard case .container(_, let children) = node else {
            return XCTFail("a TupleView with more than one child reflects to a container holding all children")
        }
        XCTAssertEqual(children.count, 2, "the container holds every child")
        let texts = children.compactMap { child -> String? in
            if case .leaf(let text, _, _) = child { return text }
            return nil
        }
        XCTAssertEqual(texts, ["First", "Second"], "both children survive, in order")
    }

    func testSingleSurvivingChildIsReturnedUnwrapped() throws {
        let node = try XCTUnwrap(PinViewReflector.reflect(labelBesideNilChild()))
        guard case .leaf(let text, _, _) = node else {
            return XCTFail("a group that reduces to one child returns that child directly, not wrapped in a container")
        }
        XCTAssertEqual(text, "Solo", "the lone surviving child is unwrapped (Color.red reflects nil and drops out)")
    }

    func testStructuralContainersReflectNil() {
        XCTAssertNil(PinViewReflector.reflect(List { PinLabel("row") }),
                     "a List reflects nil — its lazy UIKit-backed rows aren't in the reflected tree")
        XCTAssertNil(PinViewReflector.reflect(Section { PinLabel("row") }),
                     "a Section reflects nil, falling back to containment")
    }

    // A ForEach of *container* rows (the rich/2-D case the deref targets — Cart etc.) expands into its real
    // rows via PinVariadicExpander, so it no longer reflects nil. Bare-leaf rows (ForEach { PinLabel }) have
    // a different graph-node shape the deref doesn't reach; those return nil and the screen falls back to the
    // containment path (their prior behavior — a simple 1-D list containment already handles).
    func testForEachOfContainerRowsExpands() throws {
        try XCTSkipUnless(PinVariadicExpander.isHealthy, "expander unavailable on this OS — ForEach falls back to containment")
        func leaves(_ n: ReflectedNode?) -> Int {
            switch n {
            case .container(_, let c): return c.reduce(0) { $0 + leaves($1) }
            case .leaf: return 1
            default: return 0
            }
        }
        XCTAssertEqual(leaves(PinViewReflector.reflect(ForEach(["r0", "r1"], id: \.self) { name in HStack { PinLabel(name) } })), 2,
                       "ForEach of HStack rows expands → 2 leaves")
    }
}
