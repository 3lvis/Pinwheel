import UIKit

struct Device {
    public enum Kind: String {
        case iphoneXR_11 = "iPhone XR/11"
        case iphoneXS_11Pro = "iPhone XS/11 Pro"
        case iphoneSE = "iPhone SE (2nd & 3rd generation)"
        case iphone12_13Mini = "iPhone 12/13 mini"
        case iphone12_13_14 = "iPhone 12/13/14"
        case iphone12_13ProMax_14Plus = "iPhone 12/13 Pro Max/14 Plus"
        case iphone15_15Pro = "iPhone 15/15 Pro"
        case iphone15Plus_15ProMax = "iPhone 15 Plus/15 Pro Max"

        case padPortraitOneThird = "iPad Portrait 1/3"
        case padPortraitTwoThirds = "iPad Portrait 2/3"
        case padPortraitFull = "iPad Portrait Full"
        case padLandscapeOneThird = "iPad Landscape 1/3"
        case padLandscapeOneHalf = "iPad Landscape 1/2"
        case padLandscapeTwoThirds = "iPad Landscape 2/3"
        case padLandscapeFull = "iPad Landscape Full"
    }

    var kind: Kind
    var traits: UITraitCollection
    var frame: CGRect
    var autoresizingMask: UIView.AutoresizingMask
    var title: String {
        return kind.rawValue
    }

    var isEnabled: Bool {
        switch kind {
        case .iphoneXR_11, .iphoneXS_11Pro, .iphoneSE, .iphone12_13Mini, .iphone12_13_14, .iphone12_13ProMax_14Plus, .iphone15_15Pro, .iphone15Plus_15ProMax:
            let currentSize = UIScreen.main.bounds.size
            return frame.width <= currentSize.width && frame.height <= currentSize.height
        case .padLandscapeOneThird, .padLandscapeOneHalf, .padPortraitOneThird, .padPortraitTwoThirds, .padPortraitFull, .padLandscapeFull, .padLandscapeTwoThirds:
            return UIDevice.current.userInterfaceIdiom == .pad
        }
    }

    init(kind: Kind) {
        let size: CGSize
        let horizontalSizeClass: UIUserInterfaceSizeClass
        let verticalSizeClass = UIUserInterfaceSizeClass.regular
        let userInterfaceIdiom: UIUserInterfaceIdiom
        let autoresizingMask: UIView.AutoresizingMask

        switch kind {
        case .iphoneXR_11:
            size = .init(width: 414, height: 896)
        case .iphoneXS_11Pro:
            size = .init(width: 375, height: 812)
        case .iphoneSE:
            size = .init(width: 375, height: 667)
        case .iphone12_13Mini:
            size = .init(width: 360, height: 780)
        case .iphone12_13_14:
            size = .init(width: 390, height: 844)
        case .iphone12_13ProMax_14Plus:
            size = .init(width: 428, height: 926)
        case .iphone15_15Pro:
            size = .init(width: 393, height: 852)
        case .iphone15Plus_15ProMax:
            size = .init(width: 430, height: 932)
        case .padPortraitOneThird:
            size = .init(width: 320, height: UIScreen.main.bounds.height)
        case .padPortraitTwoThirds:
            size = .init(width: UIScreen.main.bounds.width - 320, height: UIScreen.main.bounds.height)
        case .padPortraitFull:
            size = UIScreen.main.bounds.size
        case .padLandscapeOneThird:
            size = .init(width: 320, height: UIScreen.main.bounds.height)
        case .padLandscapeOneHalf:
            size = .init(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height)
        case .padLandscapeTwoThirds:
            size = .init(width: UIScreen.main.bounds.width - 320, height: UIScreen.main.bounds.height)
        case .padLandscapeFull:
            size = UIScreen.main.bounds.size
        }

        var x: CGFloat = (UIScreen.main.bounds.width - size.width) / 2
        let y: CGFloat = (UIScreen.main.bounds.height - size.height) / 2

        switch kind {
        case .iphoneXR_11, .iphoneXS_11Pro, .iphoneSE, .iphone12_13Mini, .iphone12_13_14, .iphone12_13ProMax_14Plus, .iphone15_15Pro, .iphone15Plus_15ProMax:
            horizontalSizeClass = .compact
            userInterfaceIdiom = .phone
            autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        case .padLandscapeOneThird, .padLandscapeOneHalf, .padPortraitOneThird, .padPortraitTwoThirds:
            horizontalSizeClass = .compact
            userInterfaceIdiom = .pad
            autoresizingMask = [.flexibleHeight]
            x = 0
        case .padPortraitFull, .padLandscapeFull, .padLandscapeTwoThirds:
            horizontalSizeClass = .regular
            userInterfaceIdiom = .pad
            autoresizingMask = [.flexibleHeight, .flexibleWidth]
            x = 0
        }

        let traits: UITraitCollection = .init(traitsFrom: [
            .init(horizontalSizeClass: horizontalSizeClass),
            .init(verticalSizeClass: verticalSizeClass),
            .init(userInterfaceIdiom: userInterfaceIdiom)
        ])

        self.kind = kind
        self.traits = traits
        self.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
        self.autoresizingMask = autoresizingMask
    }

    public static var all: [Device] {
        var devices: [Device] = [
            Device(kind: .iphoneXR_11),
            Device(kind: .iphoneXS_11Pro),
            Device(kind: .iphoneSE),
            Device(kind: .iphone12_13Mini),
            Device(kind: .iphone12_13_14),
            Device(kind: .iphone12_13ProMax_14Plus),
            Device(kind: .iphone15_15Pro),
            Device(kind: .iphone15Plus_15ProMax)
        ]

        let isPortrait = UIDevice.current.userInterfaceIdiom == .pad && UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width
        if isPortrait {
            devices.append(contentsOf: [Device(kind: .padPortraitOneThird),
                                        Device(kind: .padPortraitTwoThirds),
                                        Device(kind: .padPortraitFull)])
        } else {
            devices.append(contentsOf: [Device(kind: .padLandscapeOneThird),
                                        Device(kind: .padLandscapeOneHalf),
                                        Device(kind: .padLandscapeTwoThirds),
                                        Device(kind: .padLandscapeFull)])
        }
        return devices
    }
}
