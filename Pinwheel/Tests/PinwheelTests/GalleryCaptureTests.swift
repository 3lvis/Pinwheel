import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

// A plain thumbnail + text-column row (the canonical list cell) collapses to one component in containment
// but reflection sees its parts. The tolerant zip falls back to matching reflection against the flattened
// leaves, so the row captures with its real nesting (thumbnail leading, then the text column) rather than
// scrambling on the containment path.
@MainActor
final class GalleryCaptureTests: XCTestCase {
    private struct Gallery: SwiftUI.View {
        static let swatch = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120)).image { context in
            UIColor.systemOrange.setFill(); context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
        }
        let rows = ["Sunset Ridge", "Ocean Deep", "Forest Trail"]
        var body: some SwiftUI.View {
            ScrollView {
                VStack(spacing: .spacingM) {
                    ForEach(rows, id: \.self) { title in
                        HStack(spacing: .spacingM) {
                            Image(uiImage: Self.swatch).resizable().frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: .radiusM))
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                PinLabel(title).font(.bodySemibold)
                                PinLabel("Sub").font(.caption).color(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.spacingM).background(.secondaryBackground).cornerRadius(.radiusM)
                    }
                }.padding(.spacingL)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(.primaryBackground)
        }
    }

    func testImageRowCapturesStructuredNotScrambled() throws {
        let size = CGSize(width: 402, height: 900)
        let controller = UIHostingController(rootView: Gallery().environment(\.pinCapturing, true))
        controller.view.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: controller.view.frame)
        window.rootViewController = controller
        window.isHidden = false
        controller.view.layoutIfNeeded()
        let document = try XCTUnwrap(PinDisplayListCapture.document(Gallery(), name: "Gallery", size: size, screenHeight: 778, liveHost: controller.view))
        XCTAssertEqual(document.root.tag, "screen",
                       "a thumbnail + text-column row captures through reflection (structured), not the containment path (scrambled)")
        func hasFill(_ node: FigmaNode) -> Bool {
            node.fillToken == "secondaryBackground" || node.children.contains(where: hasFill)
        }
        XCTAssertTrue(hasFill(document.root),
                      "the row keeps its card background fill — the reflection path must re-attach a flat-content card's fill, not drop it")
        _ = withExtendedLifetime(window) {}
    }
}
