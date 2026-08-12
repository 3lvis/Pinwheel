import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

// A row whose fill-width comes from a Spacer nested inside its text column (a receipt row: thumbnail +
// a column whose price line has a Spacer) must fill the card width, not hug and centre. Fill-width has to
// propagate up from the nested Spacer through the column to the row.
@MainActor
final class FillWidthPropagationTests: XCTestCase {
    private struct Row: SwiftUI.View {
        var body: some SwiftUI.View {
            ScrollView {
                VStack(spacing: .spacingM) {
                    ForEach(["A", "B"], id: \.self) { title in
                        HStack(spacing: .spacingM) {
                            RoundedRectangle(cornerRadius: .radiusM).fill(.primaryBackground).frame(width: 64, height: 64)
                            VStack(alignment: .leading, spacing: .spacingS) {
                                PinLabel(title).font(.bodySemibold)
                                HStack {
                                    PinLabel("qty").font(.caption)
                                    Spacer()
                                    PinLabel("kr 9").font(.bodySemibold)
                                }
                            }
                        }
                        .padding(.spacingM).background(.secondaryBackground).cornerRadius(.radiusM)
                    }
                }.padding(.spacingL)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(.primaryBackground)
        }
    }

    func testRowFillsWidthFromNestedSpacer() throws {
        let size = CGSize(width: 402, height: 900)
        let controller = UIHostingController(rootView: Row().environment(\.pinCapturing, true))
        controller.view.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: controller.view.frame)
        window.rootViewController = controller
        window.isHidden = false
        controller.view.layoutIfNeeded()
        let document = try XCTUnwrap(PinDisplayListCapture.document(Row(), name: "Row", size: size, screenHeight: 778, liveHost: controller.view))
        // The card row (secondaryBackground fill) must fill width, not hug its content.
        func findCard(_ node: FigmaNode) -> FigmaNode? {
            if node.fillToken == "secondaryBackground" { return node }
            for child in node.children { if let found = findCard(child) { return found } }
            return nil
        }
        let card = try XCTUnwrap(findCard(document.root), "the card row captures with its fill")
        XCTAssertEqual(card.fillWidth, true, "the card row fills the width (from its nested Spacer), so it doesn't hug and centre")
        _ = withExtendedLifetime(window) {}
    }
}
