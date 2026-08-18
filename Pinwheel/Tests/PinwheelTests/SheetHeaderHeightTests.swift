import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class SheetHeaderHeightTests: XCTestCase {
    private struct Fixture: SwiftUI.View {
        var body: some SwiftUI.View {
            PinwheelSheet(PinwheelSheetModel(title: "Section", commit: .init("Done") {})) {
                PickerRow(title: "Tokens", isSelected: true) {}
                PickerRow(title: "Components", isSelected: false) {}
            }
        }
    }

    func testSheetHeaderBandRunsFromTheTopEdgeToTheHairlineAtTheControlFloorPlusASpacingEachSide() throws {
        let size = CGSize(width: 402, height: 700)
        let read = try XCTUnwrap(PinDisplayList.read(Fixture(), size: size, liveControlsOnScreen: false))
        let hairline = try XCTUnwrap(
            read.leaves
                .filter { $0.frame.height <= 1.5 && $0.frame.width > size.width / 2 }
                .min(by: { $0.frame.minY < $1.frame.minY }),
            "expected a hairline under the header; leaves were \(read.leaves.map(\.frame))"
        )
        XCTAssertEqual(
            hairline.frame.minY,
            .minimumControlHeight + .spacing2 * 2,
            accuracy: 0.5,
            "the header band should be the 48pt control floor with one spacing-2 above and below"
        )
        XCTAssertEqual(
            hairline.frame.height,
            1,
            accuracy: 0.01,
            "a Divider draws a 0.33pt hairline by default, which disappears on a light surface"
        )
    }
}
