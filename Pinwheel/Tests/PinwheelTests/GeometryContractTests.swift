import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

// The concentric-radius clamp (max(outer - inset, 0)) is not reachable via @testable import Pinwheel:
// its only pure form is a `private func` on `PinNumbersDemo` in the Demo target, and the package's
// equivalent lives inside the `private struct PinConcentricBackground`. The public seam
// (pinConcentricContainer/pinConcentricBackground) exposes the radius only through a rendered
// PinDisplayList capture, and only on the pre-iOS-26 `.rect(cornerRadius:)` branch — on iOS 26 it
// uses ConcentricRectangle, whose path the capture extractor does not read as a rounded rect, so the
// radius does not surface. Asserting it would pin a runtime snapshot, not the contract. See the
// returned report for the reachable alternatives.
@MainActor
final class GeometryContractTests: XCTestCase {
}
