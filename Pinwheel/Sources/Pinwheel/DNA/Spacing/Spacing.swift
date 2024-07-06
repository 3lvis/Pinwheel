import Foundation

public struct SpacingValues {
    public static var spacingXXS: CGFloat = 2
    public static var spacingXS: CGFloat = 4
    public static var spacingXM: CGFloat = 6
    public static var spacingS: CGFloat = 8
    public static var spacingM: CGFloat = 12
    public static var spacingL: CGFloat = 16
    public static var spacingXL: CGFloat = 24
    public static var spacingXXL: CGFloat = 32
}

public extension CGFloat {

    /// Spacing 2 points.
    static var spacingXXS: CGFloat {
        get { SpacingValues.spacingXXS }
        set { SpacingValues.spacingXXS = newValue }
    }

    /// Spacing 4 points.
    static var spacingXS: CGFloat {
        get { SpacingValues.spacingXS }
        set { SpacingValues.spacingXS = newValue }
    }

    /// Spacing 6 points.
    static var spacingXM: CGFloat {
        get { SpacingValues.spacingXM }
        set { SpacingValues.spacingXM = newValue }
    }

    /// Spacing 8 points.
    static var spacingS: CGFloat {
        get { SpacingValues.spacingS }
        set { SpacingValues.spacingS = newValue }
    }

    /// Spacing 12 points.
    static var spacingM: CGFloat {
        get { SpacingValues.spacingM }
        set { SpacingValues.spacingM = newValue }
    }

    /// Spacing 16 points.
    static var spacingL: CGFloat {
        get { SpacingValues.spacingL }
        set { SpacingValues.spacingL = newValue }
    }

    /// Spacing 24 points.
    static var spacingXL: CGFloat {
        get { SpacingValues.spacingXL }
        set { SpacingValues.spacingXL = newValue }
    }

    /// Spacing 32 points.
    static var spacingXXL: CGFloat {
        get { SpacingValues.spacingXXL }
        set { SpacingValues.spacingXXL = newValue }
    }
}
