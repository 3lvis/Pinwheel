import UIKit

struct Device {
    public enum Kind: String {
        case phone4_7inch = "iPhone SE (4.7-inch)"

        case phone5_1inch = "iPhone 12 mini (5.1-inch)"

        case phone5_4_and_5_8inch = "iPhone 13 Mini & 11 Pro (5.4 & 5.8-inch)"

        case phone6_1inch = "iPhone 14 Pro (6.1-inch)"

        case phone6_5inch = "iPhone 11 Pro Max (6.5-inch)"

        case phone6_7inch = "iPhone 14 Pro Max (6.7-inch)"

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
        case .phone4_7inch, .phone5_1inch, .phone5_4_and_5_8inch, .phone6_1inch, .phone6_5inch, .phone6_7inch:
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
        case .phone4_7inch:
            size = .init(width: 375, height: 667)
        case .phone5_1inch:
            size = .init(width: 360, height: 780)
        case .phone5_4_and_5_8inch:
            size = .init(width: 375, height: 812)
        case .phone6_1inch:
            size = .init(width: 390, height: 844)
        case .phone6_5inch:
            size = .init(width: 414, height: 896)
        case .phone6_7inch:
            size = .init(width: 428, height: 926)
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
        case .phone4_7inch, .phone5_1inch, .phone5_4_and_5_8inch, .phone6_1inch, .phone6_5inch, .phone6_7inch:
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
            Device(kind: .phone4_7inch),
            Device(kind: .phone5_1inch),
            Device(kind: .phone5_4_and_5_8inch),
            Device(kind: .phone6_1inch),
            Device(kind: .phone6_5inch),
            Device(kind: .phone6_7inch),
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
