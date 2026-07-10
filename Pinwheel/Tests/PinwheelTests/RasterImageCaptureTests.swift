import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class RasterImageCaptureTests: XCTestCase {
    private static func swatch() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
    }

    private struct Fixture: SwiftUI.View {
        let image: UIImage
        var body: some SwiftUI.View {
            VStack(spacing: 16) {
                Image(uiImage: image).resizable().frame(width: 80, height: 80)
                PinLabel("Photo").font(.body)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.primaryBackground)
        }
    }

    private func imageNodes(_ node: FigmaNode) -> [FigmaNode] {
        (node.image != nil ? [node] : []) + node.children.flatMap(imageNodes)
    }

    // A raster image (a real photo, not an SF Symbol vector) must capture as an image node with pixels —
    // its DisplayList content kind is `image`, which was unhandled and dropped the photo entirely.
    func testRasterImageCapturesWithPixels() throws {
        let document = try XCTUnwrap(PinDisplayListCapture.document(
            Fixture(image: Self.swatch()), name: "Photo", size: CGSize(width: 402, height: 300), screenHeight: 300))
        let images = imageNodes(document.root)
        XCTAssertFalse(images.isEmpty, "a raster image must capture as an image node with pixels, not be dropped")
        let photo = try XCTUnwrap(images.first { abs($0.w - 80) < 4 && abs($0.h - 80) < 4 }, "the 80×80 swatch should capture at its size")
        XCTAssertNotNil(photo.image, "the image node must carry cropped pixels")
    }
}
