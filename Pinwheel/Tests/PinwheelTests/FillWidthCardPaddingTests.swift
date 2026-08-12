import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class FillWidthCardPaddingTests: XCTestCase {
    // Mirrors CardsDemo: full-width cards (.frame(maxWidth: .infinity)) with left-aligned content.
    private struct Fixture: SwiftUI.View {
        var body: some SwiftUI.View {
            ScrollView {
                VStack(spacing: .spacingM) {
                    ForEach(["Revenue", "Orders"], id: \.self) { title in
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            PinLabel(title).font(.caption).color(.secondary)
                            PinLabel("$12,480").font(.title)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.spacingL)
                        .background(.secondaryBackground)
                        .cornerRadius(.radiusM)
                    }
                }
                .padding(.spacingL)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.primaryBackground)
        }
    }

    private func cards(_ node: FigmaNode) -> [FigmaNode] {
        (node.fillToken == "secondaryBackground" && node.layout != nil ? [node] : []) + node.children.flatMap(cards)
    }

    // A full-width left-aligned card must not record the empty space to the right of its content as
    // trailing padding — the padding stays symmetric (spacing-l all round) and the card fills its parent.
    func testFullWidthCardHasSymmetricPaddingNotAGiantTrailingGap() throws {
        let document = try XCTUnwrap(PinDisplayListCapture.document(
            Fixture(), name: "Cards", size: CGSize(width: 402, height: 700), screenHeight: 700))
        let card = try XCTUnwrap(cards(document.root).first, "should capture a secondaryBackground card frame")
        let pad = try XCTUnwrap(card.layout?.pad, "the card should carry auto-layout padding")
        // pad = [top, trailing, bottom, leading]
        XCTAssertEqual(pad[1], pad[3], accuracy: 1.0,
                       "trailing padding must match leading — a left-aligned card's right gap is fill space, not padding (got trailing=\(pad[1]), leading=\(pad[3]))")
        XCTAssertEqual(card.fillWidth, true, "a full-width card should fill its parent, not force width via padding")
    }
}
