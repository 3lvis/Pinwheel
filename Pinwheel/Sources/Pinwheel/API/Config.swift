import Foundation

public struct Config {
    public static var bundle: Bundle { Bundle.pinwheel }
}

public extension Bundle {
    static var pinwheel: Bundle {
        return Bundle(for: UIPinTableViewCell.self)
    }
}
