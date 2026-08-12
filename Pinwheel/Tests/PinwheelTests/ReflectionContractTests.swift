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
    // A standalone filled/stroked shape (a thumbnail's `RoundedRectangle().fill()`) renders as a fill box the
    // containment path keeps as a component, so reflection must emit it as a leaf — else a rich row's reflected
    // leaf count falls short of the rendered components and the whole screen drops to containment (Cart's
    // 2-D card scramble). An Image (SF Symbol) must NOT be a leaf — containment drops symbols, so counting one
    // would overshoot the other way.
    func testFilledShapeReflectsToALeafButImageDoesNot() {
        XCTAssertNotNil(PinViewReflector.reflect(RoundedRectangle(cornerRadius: 8).fill(.red).frame(width: 56, height: 56)),
                        "a filled shape reflects to a leaf — the containment path keeps its fill box as a component")
        XCTAssertNil(PinViewReflector.reflect(Image(systemName: "photo")),
                     "an SF Symbol reflects nil — the containment path drops symbols, so counting it would desync the zip")
    }

    // The rich 2-D row (thumbnail | info column | stepper) reflects with the thumbnail shape leading, the
    // info as a nested column, and the quantity trailing — the structure Cart needs so Figma auto-layout
    // lays it left-to-right instead of ordering by Y (the v5 scramble).
    func testTwoDimensionalRowReflectsThumbnailInfoColumnStepper() throws {
        try XCTSkipUnless(PinVariadicExpander.isHealthy, "expander unavailable on this OS — falls back to containment")
        let row = HStack {
            RoundedRectangle(cornerRadius: 8).fill(.gray).frame(width: 56, height: 56)
            VStack(alignment: .leading) {
                PinLabel("Title").font(.body)
                PinLabel("$129").font(.bodySemibold)
            }
            Spacer()
            PinLabel("1").font(.body)
        }
        guard case .container(let outer, let top)? = PinViewReflector.reflect(row), outer.axis == .row else {
            return XCTFail("the row reflects to a horizontal container")
        }
        func firstLeafText(_ n: ReflectedNode) -> String?? {
            switch n {
            case .leaf(let t, _, _): return .some(t)
            case .container(_, let c): return c.compactMap(firstLeafText).first ?? nil
            case .spacer: return nil
            }
        }
        guard case .leaf(let leadingText, _, _) = top.first else {
            return XCTFail("the row leads with the thumbnail shape leaf")
        }
        XCTAssertNil(leadingText, "the leading leaf is the thumbnail shape (no text)")
        let texts = top.compactMap(firstLeafText).compactMap { $0 }
        XCTAssertEqual(texts, ["Title", "1"], "the info column (Title) precedes the trailing quantity, in reading order")
    }

    // An `.overlay(Capsule().stroke(color, lineWidth:))` border reflects onto the container. Reflection reads
    // the StrokeStyle's lineWidth from the view value — unlike the DisplayList, which bakes the stroke to a
    // filled ring with no readable width — so a bordered control (a stepper pill) captures its border editably.
    func testOverlayStrokeReflectsAsTheContainerBorder() throws {
        let bordered = HStack { PinLabel("−"); PinLabel("+") }
            .overlay(Capsule().stroke(Color.red, lineWidth: 2))
        guard case .container(let container, _)? = PinViewReflector.reflect(bordered) else {
            return XCTFail("a bordered HStack reflects to a container")
        }
        let border = try XCTUnwrap(container.border, "the overlay stroke is captured as the container's border")
        XCTAssertEqual(border.width, 2, "the border carries the stroke's lineWidth, read from the view value")
    }

    // A Capsule stroke border captures as a pill so the imported frame is fully rounded, not a square
    // rectangle; a RoundedRectangle stroke carries its own corner radius.
    func testCapsuleStrokeBorderCapturesAsPill() throws {
        let capsule = HStack { PinLabel("x") }.overlay(Capsule().stroke(Color.red, lineWidth: 1))
        guard case .container(let capsuleContainer, _)? = PinViewReflector.reflect(capsule),
              let capsuleBorder = capsuleContainer.border else {
            return XCTFail("the capsule-bordered container carries a border")
        }
        XCTAssertTrue(capsuleBorder.isPill, "a Capsule stroke border is a pill (fully rounded)")

        let rounded = HStack { PinLabel("x") }.overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
        guard case .container(let roundedContainer, _)? = PinViewReflector.reflect(rounded),
              let roundedBorder = roundedContainer.border else {
            return XCTFail("the rounded-rect-bordered container carries a border")
        }
        XCTAssertFalse(roundedBorder.isPill, "a RoundedRectangle stroke is not a pill")
        XCTAssertEqual(roundedBorder.cornerRadius, 8, "the RoundedRectangle border carries its corner radius")
    }

    // A bordered single leaf (a stepper drawn as one "−  1  +" label with an overlay stroke) wraps into a
    // bordered container so the border is carried and the leaf count stays 1 — matching containment, which
    // groups the ring-enclosed control into a single component (its flatten treats a box of leaves as one).
    func testBorderedLeafWrapsIntoABorderedContainer() throws {
        let bordered = PinLabel("−  1  +").overlay(Capsule().stroke(Color.red, lineWidth: 1))
        guard case .container(let container, let children)? = PinViewReflector.reflect(bordered) else {
            return XCTFail("a bordered leaf wraps into a container carrying the border")
        }
        XCTAssertNotNil(container.border, "the wrapping container carries the stroke border")
        XCTAssertEqual(children.count, 1, "the original leaf is the container's sole child")
        guard case .leaf(let text, _, _) = children.first else { return XCTFail("the child is the label leaf") }
        XCTAssertEqual(text, "−  1  +", "the label text survives the wrap")
    }

    // A fixed-size (framed) image is a deliberate thumbnail the containment path keeps as a component, so
    // reflection must count it as a leaf — else a row like a gallery cell (thumbnail + text column) reflects
    // short of the rendered components and drops to the containment path, which scrambles the 2-D row. An
    // unframed intrinsic-size image (an SF Symbol) still reflects nil, since containment drops those.
    func testFramedImageReflectsToALeafButUnframedDoesNot() {
        XCTAssertNotNil(PinViewReflector.reflect(Image(systemName: "photo").resizable().frame(width: 64, height: 64)),
                        "a fixed-size framed image reflects as a leaf")
        XCTAssertNil(PinViewReflector.reflect(Image(systemName: "plus")),
                     "an unframed image still reflects nil")
    }

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
