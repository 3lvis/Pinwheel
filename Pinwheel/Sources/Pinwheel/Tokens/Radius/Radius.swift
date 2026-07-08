import Foundation

public struct RadiusValues {
    public static var radiusM: CGFloat = 12
    public static var radiusL: CGFloat = 24
}

public extension CGFloat {
    static var radiusM: CGFloat {
        get { RadiusValues.radiusM }
        set { RadiusValues.radiusM = newValue }
    }

    static var radiusL: CGFloat {
        get { RadiusValues.radiusL }
        set { RadiusValues.radiusL = newValue }
    }
}
