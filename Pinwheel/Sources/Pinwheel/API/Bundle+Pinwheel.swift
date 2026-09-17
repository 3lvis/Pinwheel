import Foundation

extension Bundle {
    public static var pinwheel: Bundle {
        return Bundle(for: UIPinTableViewCell.self)
    }
}
