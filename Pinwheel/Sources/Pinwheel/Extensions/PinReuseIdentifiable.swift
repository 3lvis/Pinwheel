import Foundation

public protocol PinReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

extension PinReuseIdentifiable {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}
