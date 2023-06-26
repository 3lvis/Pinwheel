import UIKit

// MARK: - Semantic colors, dark mode compatible
extension UIColor {
    public class var primaryText: UIColor { Config.colorProvider.primaryText }
    public class var secondaryText: UIColor { Config.colorProvider.secondaryText }
    public class var tertiaryText: UIColor { Config.colorProvider.tertiaryText }

    public class var primaryAction: UIColor { Config.colorProvider.primaryAction }
    public class var criticalAction: UIColor { Config.colorProvider.criticalAction }

    public class var primaryBackground: UIColor { Config.colorProvider.primaryBackground }
    public class var secondaryBackground: UIColor { Config.colorProvider.secondaryBackground }
    public class var tertiaryBackground: UIColor { Config.colorProvider.tertiaryBackground }
    public class var criticalBackground: UIColor { Config.colorProvider.criticalBackground }
}

// MARK: - Public color creation methods
public extension UIColor {
    /// The UIColor initializer we need it's more natural to write integer values from 0 to 255 than decimas from 0 to 1
    /// - Parameters:
    ///   - r: red (0-255)
    ///   - g: green (0-255)
    ///   - b: blue (0-255)
    ///   - a: alpla (0-1)
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    /// Base initializer, it creates an instance of `UIColor` using an HEX string.
    ///
    /// - Parameter hex: The base HEX string to create the color.
    convenience init(hex: String) {
        let noHashString = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: noHashString)
        scanner.charactersToBeSkipped = CharacterSet.symbols

        var hexInt: UInt64 = 0
        if scanner.scanHexInt64(&hexInt) {
            let red = (hexInt >> 16) & 0xFF
            let green = (hexInt >> 8) & 0xFF
            let blue = (hexInt) & 0xFF

            self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
        } else {
            self.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        }
    }

    /// Convenience method to create dynamic colors for dark mode if the OS supports it (independant of Designable
    /// settings)
    /// - Parameters:
    ///   - defaultColor: light mode version of the color
    ///   - darkModeColor: dark mode version of the color
    @available(iOS 13.0, *)
    class func dynamicColor(defaultColor: UIColor, darkModeColor: UIColor) -> UIColor {
        UIColor { traitCollection -> UIColor in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return darkModeColor
            default:
                return defaultColor
            }
        }
    }

    /// Returns hexadecimal representation of a color converted to the sRGB color space.
    var hexString: String {
        guard
            let targetColorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let cgColor = self.cgColor.converted(to: targetColorSpace, intent: .relativeColorimetric, options: nil)
        else {
            // Not possible to convert source color space to RGB
            return "#000000"
        }
        let components = cgColor.components
        let red = components?[0] ?? 0.0
        let green = components?[1] ?? 0.0
        let blue = components?[2] ?? 0.0
        return String(format: "#%02x%02x%02x", (Int)(red * 255), (Int)(green * 255), (Int)(blue * 255))
    }
}
