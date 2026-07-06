import Foundation

public struct RadiusValues {
    public static var radiusM: CGFloat = 12
}

public extension CGFloat {
    static var radiusM: CGFloat {
        get { RadiusValues.radiusM }
        set { RadiusValues.radiusM = newValue }
    }
}
