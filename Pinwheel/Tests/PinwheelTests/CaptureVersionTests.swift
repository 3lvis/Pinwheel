import XCTest
@testable import Pinwheel

@MainActor
final class CaptureVersionTests: XCTestCase {
    private let storageKey = "PinCaptureVersions"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        super.tearDown()
    }

    func testFirstRecordReturnsVersionOne() {
        let id = UUID().uuidString
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node())), 1)
    }

    func testUnchangedStructureKeepsTheVersion() {
        let id = UUID().uuidString
        let red = RGBA(r: 1, g: 0, b: 0, a: 1)
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node(fill: red))), 1)
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node(fill: red))), 1)
    }

    func testChangedStructureIncrementsByExactlyOne() {
        let id = UUID().uuidString
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node(tag: "screen"))), 1)
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node(tag: "changed"))), 2)
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: document(root: node(tag: "changed-again"))), 3)
    }

    func testImageOnlyChangeDoesNotBumpTheVersion() {
        let id = UUID().uuidString
        let first = document(root: node(image: "AAAA", imageDark: "BBBB"))
        let repainted = document(root: node(image: "CCCC", imageDark: "DDDD"))
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: first), 1)
        XCTAssertEqual(PinCaptureVersions.shared.record(id: id, document: repainted), 1)
    }

    func testRecordedVersionIsReadableAfterRecording() {
        let id = UUID().uuidString
        XCTAssertNil(PinCaptureVersions.shared.version(for: id))
        let recorded = PinCaptureVersions.shared.record(id: id, document: document(root: node()))
        XCTAssertEqual(PinCaptureVersions.shared.version(for: id), recorded)
    }

    func testRecordPersistsTheVersionToStorageForAFreshRead() {
        let id = UUID().uuidString
        let recorded = PinCaptureVersions.shared.record(id: id, document: document(root: node()))
        let data = UserDefaults.standard.data(forKey: storageKey)
        let object = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: [String: Any]]
        XCTAssertEqual(object?[id]?["version"] as? Int, recorded)
    }

    private func document(root: FigmaNode) -> FigmaDocument {
        FigmaDocument(width: 100, height: 50, root: root, tokens: [], textStyles: [])
    }

    private func node(
        tag: String = "screen",
        fill: RGBA? = nil,
        image: String? = nil,
        imageDark: String? = nil,
        children: [FigmaNode] = []
    ) -> FigmaNode {
        FigmaNode(
            tag: tag, x: 0, y: 0, w: 100, h: 50,
            fill: fill, fillToken: nil, fillDark: nil,
            radius: nil, radiusToken: nil, component: nil, name: nil,
            font: nil, texts: nil, textAlign: nil, opacity: nil,
            image: image, imageDark: imageDark, layout: nil,
            grow: nil, ordered: nil, fillWidth: nil, children: children
        )
    }
}
