import UIKit

struct Device {
    public enum Kind: String {
        case iphoneSE = "iPhone SE (2nd & 3rd generation)"
        case iphone12_13Mini = "iPhone 12/13 mini"
        case iphoneXS_11Pro = "iPhone XS/11 Pro"
        case iphone12_13_14 = "iPhone 12/13/14/16e"
        case iphone15_15Pro_16 = "iPhone 15/15 Pro/16"
        case iphone16Pro_17 = "iPhone 16 Pro/17/17 Pro"
        case iphoneXR_11 = "iPhone XR/11"
        case iphoneAir = "iPhone Air"
        case iphone12_13ProMax_14Plus = "iPhone 12/13 Pro Max/14 Plus"
        case iphone15Plus_15ProMax_16Plus = "iPhone 15 Plus/15 Pro Max/16 Plus"
        case iphone16ProMax_17ProMax = "iPhone 16 Pro Max/17 Pro Max"
    }

    var kind: Kind
    var traits: UITraitCollection
    var frame: CGRect
    var autoresizingMask: UIView.AutoresizingMask
    var title: String {
        return kind.rawValue
    }

    var isEnabled: Bool {
        let currentSize = UIScreen.main.bounds.size
        return frame.width <= currentSize.width && frame.height <= currentSize.height
    }

    init(kind: Kind) {
        let size: CGSize

        switch kind {
        case .iphoneSE:
            size = .init(width: 375, height: 667)
        case .iphone12_13Mini:
            size = .init(width: 360, height: 780)
        case .iphoneXS_11Pro:
            size = .init(width: 375, height: 812)
        case .iphone12_13_14:
            size = .init(width: 390, height: 844)
        case .iphone15_15Pro_16:
            size = .init(width: 393, height: 852)
        case .iphone16Pro_17:
            size = .init(width: 402, height: 874)
        case .iphoneXR_11:
            size = .init(width: 414, height: 896)
        case .iphoneAir:
            size = .init(width: 420, height: 912)
        case .iphone12_13ProMax_14Plus:
            size = .init(width: 428, height: 926)
        case .iphone15Plus_15ProMax_16Plus:
            size = .init(width: 430, height: 932)
        case .iphone16ProMax_17ProMax:
            size = .init(width: 440, height: 956)
        }

        let x: CGFloat = (UIScreen.main.bounds.width - size.width) / 2
        let y: CGFloat = (UIScreen.main.bounds.height - size.height) / 2

        let traits: UITraitCollection = .init(traitsFrom: [
            .init(horizontalSizeClass: .compact),
            .init(verticalSizeClass: .regular),
            .init(userInterfaceIdiom: .phone)
        ])

        self.kind = kind
        self.traits = traits
        self.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        self.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
    }

    public static var all: [Device] {
        return [
            Device(kind: .iphoneSE),
            Device(kind: .iphone12_13Mini),
            Device(kind: .iphoneXS_11Pro),
            Device(kind: .iphone12_13_14),
            Device(kind: .iphone15_15Pro_16),
            Device(kind: .iphone16Pro_17),
            Device(kind: .iphoneXR_11),
            Device(kind: .iphoneAir),
            Device(kind: .iphone12_13ProMax_14Plus),
            Device(kind: .iphone15Plus_15ProMax_16Plus),
            Device(kind: .iphone16ProMax_17ProMax)
        ]
    }
}
