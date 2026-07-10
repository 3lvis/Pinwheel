import UIKit

// The design tokens the capture value-matches rendered values against and emits as Figma variables.
// Defaults to Pinwheel's own tokens; a consumer sets `PinCaptureTokens.current` to their palette so THEIR
// colors, spacings, radii, and font bind — the capture engine stays library-agnostic. (Text-style *names*
// still match Pinwheel's `PinTextStyle` — a follow-up.)
@MainActor
public struct PinCaptureTokens {
    public struct ColorToken {
        let name: String
        let light: RGBA
        let dark: RGBA
        let textEligible: Bool

        /// A text color binds only to a text-eligible token — a background/surface token matched purely by
        /// value (a literal white == a light background) would flip the text dark on a dark-mode import.
        public init(name: String, light: UIColor, dark: UIColor, textEligible: Bool = true) {
            self.name = name
            self.light = RGBA(light)
            self.dark = RGBA(dark)
            self.textEligible = textEligible
        }

        init(name: String, light: RGBA, dark: RGBA, textEligible: Bool) {
            self.name = name
            self.light = light
            self.dark = dark
            self.textEligible = textEligible
        }
    }

    public struct FloatToken {
        let name: String
        let value: Double
        public init(name: String, value: Double) {
            self.name = name
            self.value = value
        }
    }

    public struct TextStyleToken {
        let name: String
        let family: String
        let size: Double
        let weight: Int
        public init(name: String, family: String, size: Double, weight: Int) {
            self.name = name
            self.family = family
            self.size = size
            self.weight = weight
        }
    }

    public var colors: [ColorToken]
    public var spacings: [FloatToken]
    public var radii: [FloatToken]
    public var textStyles: [TextStyleToken]
    /// The design-face name for the system font (whose internal family name isn't Figma-loadable). Custom
    /// (non-system) fonts capture their real family, so this only names the fallback.
    public var systemFontFamily: String

    public init(colors: [ColorToken], spacings: [FloatToken], radii: [FloatToken], systemFontFamily: String, textStyles: [TextStyleToken] = []) {
        self.colors = colors
        self.spacings = spacings
        self.radii = radii
        self.systemFontFamily = systemFontFamily
        self.textStyles = textStyles
    }

    /// The active registry the capture matchers consult. A consumer assigns their own at launch.
    public static var current: PinCaptureTokens = .pinwheel

    static var pinwheel: PinCaptureTokens {
        PinCaptureTokens(
            colors: PinColorToken.allCases.map {
                ColorToken(name: $0.rawValue, light: RGBA($0.color, style: .light), dark: RGBA($0.color, style: .dark),
                           textEligible: !$0.rawValue.hasSuffix("Background"))
            },
            spacings: PinFloatTokens.spacing.map { FloatToken(name: $0.name, value: Double($0.value)) },
            radii: PinFloatTokens.radius.map { FloatToken(name: $0.name, value: Double($0.value)) },
            systemFontFamily: "SF Pro Rounded",
            textStyles: PinTextStyle.allCapturable.map {
                let metrics = $0.captureMetrics
                return TextStyleToken(name: $0.captureName, family: metrics.family, size: metrics.size, weight: metrics.weight)
            }
        )
    }

    // MARK: Matching (value → token name), preserving the engine's existing tolerances.

    func colorName(for color: UIColor, textRoleOnly: Bool = false) -> String? {
        let target = RGBA(color)
        return colors.first { token in
            (!textRoleOnly || token.textEligible) && close(token.light, target)
        }?.name
    }

    func spacingName(for value: Double) -> String? { exactFloat(value, in: spacings) }
    func radiusName(for value: Double) -> String? { exactFloat(value, in: radii) }

    // Match a rendered font to a text style by size + weight (the same size/weight a Figma text style
    // carries), so captured text binds the consumer's named style.
    func textStyleName(for font: UIFont) -> String? {
        let weight = Self.cssWeight(font)
        return textStyles.first { abs($0.size - Double(font.pointSize)) < 0.5 && $0.weight == weight }?.name
    }

    static func cssWeight(_ font: UIFont) -> Int {
        let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        switch (traits?[.weight] as? CGFloat) ?? 0 {
        case ..<(-0.5): return 200
        case ..<(-0.2): return 300
        case ..<0.15: return 400
        case ..<0.28: return 500
        case ..<0.37: return 600
        case ..<0.5: return 700
        default: return 800
        }
    }

    // A measured gap reads a hair wider than the declared spacing (glyph/SF Symbol bearing insets the
    // frame), so round down to the token at or just below it.
    func gapName(for value: Double) -> String? {
        guard value > 0.5,
              let best = spacings.filter({ $0.value <= value + 0.5 }).max(by: { $0.value < $1.value }),
              value - best.value < 3 else { return nil }
        return best.name
    }

    private func exactFloat(_ value: Double, in table: [FloatToken]) -> String? {
        guard value > 0.5 else { return nil }
        return table.first { abs($0.value - value) < 0.5 }?.name
    }

    private func close(_ a: RGBA, _ b: RGBA) -> Bool {
        abs(a.r - b.r) < 0.02 && abs(a.g - b.g) < 0.02 && abs(a.b - b.b) < 0.02 && abs(a.a - b.a) < 0.05
    }

    // MARK: Emission (registry → Figma variables).

    var figmaColorTokens: [FigmaToken] {
        colors.map { FigmaToken(name: $0.name, type: "color", value: $0.light, dark: $0.dark) }
    }
    var figmaFloatTokens: [FigmaToken] {
        (spacings + radii).map { FigmaToken(name: $0.name, type: "float", float: $0.value) }
    }
    var figmaTextStyles: [FigmaTextStyle] {
        textStyles.map { FigmaTextStyle(name: $0.name, family: $0.family, size: $0.size, weight: $0.weight) }
    }
}
