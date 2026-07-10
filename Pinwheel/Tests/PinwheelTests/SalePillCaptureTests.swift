import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class SalePillCaptureTests: XCTestCase {
    // Multiple identical rows so the reflection + componentization path is taken (the on-screen sweep path),
    // mirroring CartDemo where the SALE pill's fill dropped.
    private struct Fixture: SwiftUI.View {
        var body: some SwiftUI.View {
            ScrollView {
                VStack(spacing: .spacingM) {
                    ForEach(["Alpha", "Bravo", "Charlie"], id: \.self) { name in
                        HStack(spacing: .spacingM) {
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                HStack(spacing: .spacingS) {
                                    PinLabel(name).font(.body)
                                    PinLabel("SALE").font(.footnote).color(.custom(.white))
                                        .padding(.horizontal, .spacingS).padding(.vertical, 2)
                                        .background(.criticalBackground, in: Capsule())
                                }
                                PinLabel("$10").font(.bodySemibold)
                            }
                            Spacer()
                        }
                        .padding(.spacingM)
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

    private func hasFill(_ node: FigmaNode, token: String) -> Bool {
        node.fillToken == token || node.children.contains { hasFill($0, token: token) }
    }

    // A pill (a fill + radius wrapping a single label, like a SALE badge) must keep its fill through the
    // containment vertical-list path — flattenLeaves used to dissolve the pill wrapper down to its bare
    // label, dropping the capsule and leaving white text invisible on a light card.
    func testSalePillFillSurvivesCapture() throws {
        let document = try XCTUnwrap(PinDisplayListCapture.document(
            Fixture(), name: "Sale", size: CGSize(width: 402, height: 700), screenHeight: 700))
        XCTAssertTrue(hasFill(document.root, token: "criticalBackground"),
                      "the SALE pill's criticalBackground capsule must survive — else the white label is invisible")
    }
}
