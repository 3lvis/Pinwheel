import SwiftUI

// A `Pin*` view's own description of how it renders, in design-token terms. An export
// layer reads real style from the component instead of re-specifying it at the call
// site (which drifts). These are design facts (token names, radius, typography); any
// Figma/other mapping lives in the consumer.
public struct PinCapturedComponent {
    public let name: String
    public let text: String?
    public let cornerRadius: CGFloat?
    public let fillTokenName: String?
    public let textColorTokenName: String?
    public let textStyle: PinTextStyle?
    public let centersText: Bool
    public let bounds: Anchor<CGRect>
}

public struct PinCaptureKey: PreferenceKey {
    public static let defaultValue: [PinCapturedComponent] = []
    public nonisolated static func reduce(value: inout [PinCapturedComponent], nextValue: () -> [PinCapturedComponent]) {
        value.append(contentsOf: nextValue())
    }
}

// Internal: only `Pin*` views emit; consumers read `PinCaptureKey`.
extension View {
    func pinCaptured(
        name: String,
        text: String? = nil,
        cornerRadius: CGFloat? = nil,
        fillTokenName: String? = nil,
        textColorTokenName: String? = nil,
        textStyle: PinTextStyle? = nil,
        centersText: Bool = false
    ) -> some View {
        anchorPreference(key: PinCaptureKey.self, value: .bounds) { anchor in
            [PinCapturedComponent(
                name: name,
                text: text,
                cornerRadius: cornerRadius,
                fillTokenName: fillTokenName,
                textColorTokenName: textColorTokenName,
                textStyle: textStyle,
                centersText: centersText,
                bounds: anchor
            )]
        }
    }
}
