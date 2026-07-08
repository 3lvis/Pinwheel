import SwiftUI
import ImageIO

public struct PinComponentStyle {
    public let name: String
    public let text: String?
    public let textStyle: PinTextStyle?
    public let textColorTokenName: String?
    public let fillTokenName: String?
    public let textColor: Color?
    public let fillColor: Color?
    public let cornerRadius: CGFloat?
    public let centersText: Bool
    public let underline: Bool
    public let enabled: Bool

    public init(
        name: String,
        text: String?,
        textStyle: PinTextStyle?,
        textColorTokenName: String?,
        fillTokenName: String?,
        textColor: Color? = nil,
        fillColor: Color? = nil,
        cornerRadius: CGFloat?,
        centersText: Bool,
        underline: Bool = false,
        enabled: Bool = true
    ) {
        self.name = name
        self.text = text
        self.textStyle = textStyle
        self.textColorTokenName = textColorTokenName
        self.fillTokenName = fillTokenName
        self.textColor = textColor
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
        self.centersText = centersText
        self.underline = underline
        self.enabled = enabled
    }

    /// Distinct capture names keep visual variants from collapsing onto one Figma master.
    public func named(_ name: String) -> PinComponentStyle {
        PinComponentStyle(
            name: name, text: text, textStyle: textStyle, textColorTokenName: textColorTokenName,
            fillTokenName: fillTokenName, textColor: textColor, fillColor: fillColor,
            cornerRadius: cornerRadius, centersText: centersText, underline: underline, enabled: enabled
        )
    }
}

public protocol PinFillToken {
    var captureFillToken: String? { get }
    var captureFillColor: Color? { get }
}

public protocol PinTextColorToken {
    var captureTextColorToken: String? { get }
    var captureTextColor: Color? { get }
}

public extension PinFillToken {
    var captureFillColor: Color? { nil }
}

public extension PinTextColorToken {
    var captureTextColor: Color? { nil }
}

public struct PinCapturedComponent {
    public let style: PinComponentStyle
    public let bounds: Anchor<CGRect>
    public let image: String?
    public let isContainer: Bool
    public let needsRasterization: Bool
    public let layout: PinCaptureLayout?

    public init(
        style: PinComponentStyle, bounds: Anchor<CGRect>, image: String? = nil,
        isContainer: Bool = false, needsRasterization: Bool = false, layout: PinCaptureLayout? = nil
    ) {
        self.style = style
        self.bounds = bounds
        self.image = image
        self.isContainer = isContainer
        self.needsRasterization = needsRasterization
        self.layout = layout
    }
}

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

    public init(axis: Axis, spacing: CGFloat, padding: EdgeInsets = EdgeInsets(), spaceBetween: Bool = false, alignment: CrossAxis = .center, mainAxisAlignment: CrossAxis = .leading, minWidth: CGFloat? = nil) {
        self.axis = axis
        self.spacing = spacing
        self.padding = padding
        self.spaceBetween = spaceBetween
        self.alignment = alignment
        self.mainAxisAlignment = mainAxisAlignment
        self.minWidth = minWidth
    }
}

public extension EnvironmentValues {
    /// A lazy container (`PinList`) lays out no off-screen rows, so they emit no capture descriptors unless it lays out eagerly under capture.
    @Entry var pinCapturing: Bool = false

    @Entry var pinCaptureSink: (@MainActor (String, [PinCapturedComponent], GeometryProxy) -> Void)? = nil
}

public struct PinCaptureKey: PreferenceKey {
    public static let defaultValue: [PinCapturedComponent] = []
    public nonisolated static func reduce(value: inout [PinCapturedComponent], nextValue: () -> [PinCapturedComponent]) {
        value.append(contentsOf: nextValue())
    }
}

public extension View {
    func pinCaptured(_ style: PinComponentStyle) -> some View {
        anchorPreference(key: PinCaptureKey.self, value: .bounds) { anchor in
            [PinCapturedComponent(style: style, bounds: anchor)]
        }
    }

    /// `transformAnchorPreference` appends the container; plain `anchorPreference` would replace the descendants' captured nodes with just this one.
    func pinCapturedContainer(name: String, fillTokenName: String? = nil, fillColor: Color? = nil, cornerRadius: CGFloat? = nil, enabled: Bool = true, layout: PinCaptureLayout? = nil) -> some View {
        transformAnchorPreference(key: PinCaptureKey.self, value: .bounds) { value, anchor in
            value.append(PinCapturedComponent(
                style: PinComponentStyle(
                    name: name, text: nil, textStyle: nil, textColorTokenName: nil,
                    fillTokenName: fillTokenName, fillColor: fillColor, cornerRadius: cornerRadius,
                    centersText: false, enabled: enabled
                ),
                bounds: anchor,
                isContainer: true,
                layout: layout
            ))
        }
    }

    func pinCapturedRasterized(name: String, image: String? = nil) -> some View {
        transformAnchorPreference(key: PinCaptureKey.self, value: .bounds) { value, anchor in
            value.append(PinCapturedComponent(
                style: PinComponentStyle(
                    name: name, text: nil, textStyle: nil, textColorTokenName: nil,
                    fillTokenName: nil, cornerRadius: nil, centersText: false
                ),
                bounds: anchor,
                image: image,
                needsRasterization: image == nil
            ))
        }
    }

    /// The live-window crop races layout and bakes in whatever's behind the view, so a thin element (a spinner) captures blank or mismatched; render off-screen instead.
    @MainActor func pinCapturedRendered(name: String, scale: CGFloat = 3) -> some View {
        pinCapturedRasterized(name: name, image: PinCaptureRasterizer.base64PNG(of: self, scale: scale))
    }
}

@MainActor
enum PinCaptureRasterizer {
    static func base64PNG<Content: View>(of view: Content, scale: CGFloat) -> String? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let cgImage = renderer.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return (data as Data).base64EncodedString()
    }
}
