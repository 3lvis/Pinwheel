import SwiftUI

public struct PinCaptureLayout {
    public enum Axis { case row, column }
    public enum CrossAxis { case leading, center, trailing }
    public let axis: Axis
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let spaceBetween: Bool
    public let alignment: CrossAxis
    public let mainAxisAlignment: CrossAxis
    public let minWidth: CGFloat?
    // An AUTO size makes the plugin shrink a row to its text; FIXED holds the width the capture measured.
    public let primaryAxisFixed: Bool
    // A hugged cross axis collapses to the widest child, so centred alignment drifts off-centre.
    public let counterAxisFixed: Bool

    public init(axis: Axis, spacing: CGFloat, padding: EdgeInsets = EdgeInsets(), spaceBetween: Bool = false, alignment: CrossAxis = .center, mainAxisAlignment: CrossAxis = .leading, minWidth: CGFloat? = nil, primaryAxisFixed: Bool = false, counterAxisFixed: Bool = false) {
        self.axis = axis
        self.spacing = spacing
        self.padding = padding
        self.spaceBetween = spaceBetween
        self.alignment = alignment
        self.mainAxisAlignment = mainAxisAlignment
        self.minWidth = minWidth
        self.primaryAxisFixed = primaryAxisFixed
        self.counterAxisFixed = counterAxisFixed
    }
}

public extension EnvironmentValues {
    @Entry var pinCaptureSink: (@MainActor @Sendable (String) -> Void)? = nil
    // Set by the capture pipeline: a UIKit-backed `List` is invisible to the DisplayList, so PinList
    // renders an eager stack while this is on.
    @Entry var pinCapturing: Bool = false
}
