import UIKit
import Designable

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    lazy var data: [DesignableSection] = {
        return [
            DesignableSection(title: "DNA", items: [
                DesignableItem(title: "Font", viewController: DesignableViewController<FontDesignableView>()),
                DesignableItem(title: "Color", viewController: DesignableViewController<ColorDesignableView>()),
                DesignableItem(title: "Spacing", viewController: DesignableViewController<SpacingDesignableView>()),
            ]),
            DesignableSection(title: "Components", items: [
                DesignableItem(title: "BottomSheet", viewController: BottomSheetDesignableViewController()),
                DesignableItem(title: "Label", viewController: DesignableViewController<LabelDesignableView>()),
            ]),
            DesignableSection(title: "Cells", items: [
                DesignableItem(title: "Basic", viewController: DesignableViewController<BasicCellDesignableView>()),
                DesignableItem(title: "Basic Variations", viewController: DesignableViewController<BasicCellVariationsDesignableView>()),
            ]),
            DesignableSection(title: "Reciclable", items: [
                DesignableItem(title: "Basic", viewController: DesignableViewController<BasicTableViewDesignableView>()),
            ]),
        ]
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { fatalError("Window not found") }

        Config.colorProvider = DemoColorProvider()
        Config.fontProvider = DemoFontProvider()

        let viewController = DesignableTableViewController(sections: data)
        window.rootViewController = NavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()

        return true
    }
}
