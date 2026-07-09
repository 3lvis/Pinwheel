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
    // Hold the captured main-axis size instead of hugging the content — a fixed-width colored bar whose
    // text is centered inside, not shrink-wrapped to the glyphs.
    public let primaryAxisFixed: Bool
    // Hold the captured cross-axis size so `.center`/`.trailing` alignment positions within the real
    // width — a hugged cross axis collapses to the widest child and drifts off-center.
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
    @Entry var pinCaptureSink: (@MainActor (String) -> Void)? = nil
}
