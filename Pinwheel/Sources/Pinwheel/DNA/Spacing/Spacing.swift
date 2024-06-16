import Foundation

public struct SpacingValues {
    public static var spacingXS: CGFloat = 4
    public static var spacingS: CGFloat = 8
    public static var spacingM: CGFloat = 12
    public static var spacingL: CGFloat = 16
    public static var spacingXL: CGFloat = 24
    public static var spacingXXL: CGFloat = 32
}

public extension CGFloat {
    static var spacingXS: CGFloat {
        get { SpacingValues.spacingXS }
        set { SpacingValues.spacingXS = newValue }
    }

    static var spacingS: CGFloat {
        get { SpacingValues.spacingS }
        set { SpacingValues.spacingS = newValue }
    }

    static var spacingM: CGFloat {
        get { SpacingValues.spacingM }
        set { SpacingValues.spacingM = newValue }
    }

    static var spacingL: CGFloat {
        get { SpacingValues.spacingL }
        set { SpacingValues.spacingL = newValue }
    }

    static var spacingXL: CGFloat {
        get { SpacingValues.spacingXL }
        set { SpacingValues.spacingXL = newValue }
    }

    static var spacingXXL: CGFloat {
        get { SpacingValues.spacingXXL }
        set { SpacingValues.spacingXXL = newValue }
    }
}
