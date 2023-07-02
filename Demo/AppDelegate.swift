import UIKit
import Pinwheel

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    lazy var data: [PinwheelSection] = {
        return [
            PinwheelSection(title: "DNA", items: [
                PinwheelItem(title: "Font", viewController: PinwheelViewController<FontPinwheelView>()),
                PinwheelItem(title: "Color", viewController: PinwheelViewController<ColorPinwheelView>()),
                PinwheelItem(title: "Spacing", viewController: PinwheelViewController<SpacingPinwheelView>()),
            ]),
            PinwheelSection(title: "Components", items: [
                PinwheelItem(title: "BottomSheet", viewController: BottomSheetPinwheelViewController()),
                PinwheelItem(title: "Label", viewController: PinwheelViewController<LabelPinwheelView>()),
                PinwheelItem(title: "Tweakable", viewController: PinwheelViewController<TweakablePinwheelView>()),
            ]),
            PinwheelSection(title: "Cells", items: [
                PinwheelItem(title: "Basic", viewController: PinwheelViewController<BasicCellPinwheelView>()),
                PinwheelItem(title: "Basic Variations", viewController: PinwheelViewController<BasicCellVariationsPinwheelView>()),
            ]),
            PinwheelSection(title: "Reciclable", items: [
                PinwheelItem(title: "Basic", viewController: PinwheelViewController<BasicTableViewPinwheelView>()),
            ]),
        ]
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { fatalError("Window not found") }

        // Config.colorProvider = DemoColorProvider()
        // Config.fontProvider = DemoFontProvider()

        let viewController = PinwheelTableViewController(sections: data)
        window.rootViewController = NavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()

        return true
    }
}
