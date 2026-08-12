import XCTest
import SwiftUI
import UIKit
@testable import Demo
@testable import Pinwheel

@MainActor
final class ReflectedDemoCaptureTests: XCTestCase {
    /// A demo built from a `ForEach` once trapped the reflector and took the app down as the catalog
    /// opened it, so capture every demo the catalog can auto-push rather than one that happened to break.
    func testEveryCatalogDemoCapturesWithoutTrappingTheReflector() throws {
        let entries = FigmaCatalog.entries
        XCTAssertFalse(entries.isEmpty, "the catalog should offer entries to capture")

        for entry in entries where !entry.item.isUIKitHosted {
            let document = PinDisplayListCapture.document(
                entry.item.swiftUIView(),
                name: entry.title,
                size: FigmaCatalog.captureCanvas,
                screenHeight: FigmaCatalog.oneScreen
            )
            XCTAssertNotNil(document, "\(entry.id) should capture rather than trap the reflector")
        }
    }
}
