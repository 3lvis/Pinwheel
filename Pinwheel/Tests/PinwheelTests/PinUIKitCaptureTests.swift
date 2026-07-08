import XCTest
import UIKit
@testable import Pinwheel

@MainActor
final class PinUIKitCaptureTests: XCTestCase {
    private let canvas = CGSize(width: 402, height: 1600)
    private let oneScreen: CGFloat = 778

    private func capture(_ host: UIView) -> FigmaDocument? {
        let window = UIWindow(frame: CGRect(origin: .zero, size: canvas))
        host.frame = CGRect(origin: .zero, size: canvas)
        window.addSubview(host)
        window.isHidden = false
        window.layoutIfNeeded()
        return withExtendedLifetime(window) {
            PinUIKitCapture.document(host: host, name: "Test", size: canvas, screenHeight: oneScreen)
        }
    }

    private func textNodes(_ node: FigmaNode) -> [FigmaNode] {
        ((node.texts?.isEmpty == false) ? [node] : []) + node.children.flatMap { textNodes($0) }
    }

    private func firstText(_ node: FigmaNode, _ text: String) -> FigmaNode? {
        if (node.texts ?? []).contains(where: { $0.text == text }) { return node }
        for child in node.children { if let found = firstText(child, text) { return found } }
        return nil
    }

    // A UILabel filling its host with centered text sits mid-screen; the capture must keep it there,
    // lifting only the safe-area inset — not the topmost node's y, which would pin it to the top.
    func testCenteredContentStaysCenteredNotPinnedToTop() throws {
        let host = UIView()
        let label = UILabel()
        label.text = "Centered"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: host.centerYAnchor),
        ])
        let document = try XCTUnwrap(capture(host), "a centered label should capture")
        let node = try XCTUnwrap(firstText(document.root, "Centered"))
        XCTAssertGreaterThan(node.y, 200, "centered content must not be lifted to the top of the frame")
    }

    // The color demo's swatch is the cell's backgroundColor; the row node must carry it as a token fill.
    func testTableCellBackgroundBecomesTheRowFillToken() throws {
        let source = ColorRowsSource(colors: [.actionText, .criticalText])
        let table = UITableView()
        table.dataSource = source
        table.rowHeight = 40
        table.reloadData()
        let host = UIView()
        table.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: host.topAnchor),
            table.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        let document = try withExtendedLifetime(source) { try XCTUnwrap(capture(host), "the table should capture") }
        let rows = document.root.children.filter { $0.name == "Row" }
        XCTAssertEqual(rows.first?.fillToken, "actionText", "the cell's background color is the row's fill")
        XCTAssertEqual(rows.count, 2, "both color rows capture")
    }

    // A UILabel with a background (a spacing/radius bar) captures as a filled, rounded frame — not just text.
    func testLabelWithBackgroundCapturesTokenFillAndRadius() throws {
        let host = UIView()
        let label = UILabel()
        label.text = "radiusM"
        label.backgroundColor = .actionBackground
        label.layer.cornerRadius = .radiusM
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: host.topAnchor, constant: 100),
            label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            label.heightAnchor.constraint(equalToConstant: 60),
        ])
        let document = try XCTUnwrap(capture(host))
        let bar = try XCTUnwrap(firstNode(document.root) { $0.fillToken == "actionBackground" },
                                "the label's background captures as a token fill")
        XCTAssertEqual(bar.radiusToken, "radius-m", "the label's corner radius tokenizes")
        XCTAssertFalse(textNodes(bar).isEmpty, "the bar still carries its text")
    }

    // A short string in a fill-wide label frame must capture at its glyph width, not the frame width, or
    // Figma justifies it across the box ("s u b t i t l e").
    func testShortTextCapturesTightNotStretchedAcrossAWideFrame() throws {
        let host = UIView()
        let label = UILabel()
        label.text = "Hi"
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: host.topAnchor, constant: 50),
            label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: host.trailingAnchor),
        ])
        let document = try XCTUnwrap(capture(host))
        let node = try XCTUnwrap(firstText(document.root, "Hi"))
        XCTAssertLessThan(node.w, 100, "a 2-character string must not span the full-width label frame")
    }

    // A themed UITextView captures its text with the token, so it adapts in dark mode.
    func testThemedTextViewCapturesItsColorToken() throws {
        let host = UIView()
        let textView = UITextView()
        textView.text = "Body copy"
        textView.textColor = .primaryText
        textView.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: host.topAnchor, constant: 80),
            textView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 120),
        ])
        let document = try XCTUnwrap(capture(host))
        let node = try XCTUnwrap(firstText(document.root, "Body copy"))
        XCTAssertEqual(node.font?.colorToken, "primaryText", "a themed textview tokenizes so it adapts in dark")
    }

    // A recycled table only realizes its visible window; the capture must force every cell to realize,
    // so a list taller than the viewport still captures all its rows.
    func testForceRealizeCapturesRowsBeyondTheViewport() throws {
        let source = ColorRowsSource(colors: Array(repeating: .primaryBackground, count: 30))
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 402, height: 300))
        table.dataSource = source
        table.rowHeight = 44
        table.reloadData()
        let host = UIView()
        host.addSubview(table)
        let document = try withExtendedLifetime(source) { try XCTUnwrap(capture(host)) }
        let rows = document.root.children.filter { $0.name == "Row" }
        XCTAssertEqual(rows.count, 30, "all 30 rows must capture, not just the ~7 that fit the 300pt viewport")
    }

    // Text must bind a typography token (its PinTextStyle), derived from the resolved font, so Figma maps
    // a text style — the same shared figmaFont path serves the SwiftUI leaf capture too.
    func testCapturedTextCarriesItsTypographyStyleToken() throws {
        let host = UIView()
        let label = UILabel()
        label.font = .subtitle
        label.text = "Heading"
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: host.topAnchor, constant: 40),
            label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
        ])
        let document = try XCTUnwrap(capture(host))
        let node = try XCTUnwrap(firstText(document.root, "Heading"))
        XCTAssertEqual(node.font?.style, "subtitle", "text binds its typography token so Figma maps a text style")
        XCTAssertFalse(document.textStyles.isEmpty, "the document ships the typography tokens")
    }

    // A rounded, colored UIView (a concentric-radius layer) must capture as a token fill + radius, not
    // be walked through as an invisible container.
    func testRoundedColoredViewCapturesAsAFillShape() throws {
        let host = UIView()
        let shape = UIView()
        shape.backgroundColor = .actionBackground
        shape.layer.cornerRadius = .radiusM
        shape.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(shape)
        NSLayoutConstraint.activate([
            shape.topAnchor.constraint(equalTo: host.topAnchor, constant: 40),
            shape.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 20),
            shape.widthAnchor.constraint(equalToConstant: 200),
            shape.heightAnchor.constraint(equalToConstant: 96),
        ])
        let document = try XCTUnwrap(capture(host), "a rounded colored view should capture")
        let fill = firstNode(document.root) { $0.fillToken == "actionBackground" && $0.radiusToken == "radius-m" }
        XCTAssertNotNil(fill, "a rounded colored view must capture as a fill shape carrying its radius token")
    }

    // A semibold shares its regular counterpart's size, so tokenizing must use weight to tell them apart.
    func testSemiboldTokenizesDistinctlyFromItsRegularWeight() throws {
        let host = UIView()
        let label = UILabel()
        label.font = .titleSemibold
        label.text = "Heading"
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: host.topAnchor, constant: 40),
            label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
        ])
        let document = try XCTUnwrap(capture(host))
        let node = try XCTUnwrap(firstText(document.root, "Heading"))
        XCTAssertEqual(node.font?.style, "titleSemibold", "a semibold must not collapse onto its regular-weight token")
    }

    // A colored label captures as an auto-layout frame, so the plugin renders its text inline instead of
    // wrapping it in an extra frame (one less nesting level per bar).
    func testColoredLabelIsAnAutoLayoutFrame() throws {
        let host = UIView()
        let label = UILabel()
        label.text = "Bar"
        label.textAlignment = .center
        label.backgroundColor = .tertiaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: host.topAnchor, constant: 40),
            label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            label.widthAnchor.constraint(equalToConstant: 200),
            label.heightAnchor.constraint(equalToConstant: 40)
        ])
        let document = try XCTUnwrap(capture(host))
        let bar = try XCTUnwrap(firstNode(document.root) { $0.fillToken == "tertiaryText" })
        XCTAssertNotNil(bar.layout, "a colored label is an auto-layout frame so its text renders inline")
    }

    // A UIStackView maps directly to Figma auto-layout — it must capture as an auto-layout frame, not
    // flatten its arranged subviews into absolute positions.
    func testStackViewCapturesAsAnAutoLayoutFrame() throws {
        let host = UIView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = .spacingM
        stack.translatesAutoresizingMaskIntoConstraints = false
        for text in ["One", "Two"] {
            let label = UILabel()
            label.text = text
            stack.addArrangedSubview(label)
        }
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: host.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16)
        ])
        let document = try XCTUnwrap(capture(host))
        let frame = try XCTUnwrap(firstNode(document.root) { $0.layout?.mode == "column" && $0.children.count == 2 },
                                  "a UIStackView should capture as an auto-layout column frame with its arranged subviews as children")
        XCTAssertEqual(frame.layout?.rowGap ?? -1, Double(CGFloat.spacingM), accuracy: 0.5, "the stack spacing becomes the row gap")
    }

    private func firstNode(_ node: FigmaNode, where predicate: (FigmaNode) -> Bool) -> FigmaNode? {
        if predicate(node) { return node }
        for child in node.children { if let found = firstNode(child, where: predicate) { return found } }
        return nil
    }
}

private final class ColorRowsSource: NSObject, UITableViewDataSource {
    let colors: [UIColor]
    init(colors: [UIColor]) { self.colors = colors }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { colors.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = colors[indexPath.row]
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }
}
