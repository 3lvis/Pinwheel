import Foundation

public struct Config {
    public static var bundle: Bundle { Bundle.pinwheel }
    public static var fontProvider: FontProvider = DefaultFontProvider()
    public static var colorProvider: ColorProvider = DefaultColorProvider()
}

public extension Bundle {
    static var pinwheel: Bundle {
        return Bundle(for: BasicTableViewCell.self)
    }
}
