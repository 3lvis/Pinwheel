import UIKit

public struct DefaultColorProvider: ColorProvider {
    public var primaryText: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return UIColor(hex: "000000")
        }
    }

    public var secondaryText: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondaryLabel
        } else {
            return UIColor(hex: "3C3C4399")
        }
    }

    public var tertiaryText: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiaryLabel
        } else {
            return UIColor(hex: "3C3C434C")
        }
    }

    public var actionText: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemBlue
        } else {
            return UIColor(hex: "007AFF")
        }
    }

    public var criticalText: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemRed
        } else {
            return UIColor(hex: "FF3B30")
        }
    }

    public var primaryBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemBackground
        } else {
            return UIColor(hex: "FFFFFF")
        }
    }

    public var secondaryBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.secondarySystemBackground
        } else {
            return UIColor(hex: "F2F2F7")
        }
    }

    public var actionBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemBlue.withAlphaComponent(0.4)
        } else {
            return UIColor(hex: "B3D7FF")
        }
    }

    public var criticalBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.systemRed.withAlphaComponent(0.4)
        } else {
            return UIColor(hex: "FF3B30")
        }
    }
}
