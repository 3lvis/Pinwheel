import SwiftUI
import UIKit
import Pinwheel

@main
struct DemoApp: App {
    init() {
        // UI tests launch with `-UITesting`: start from a clean slate so a prior
        // run's persisted catalog selection/device can't leak in, and disable
        // animations so presentations don't slow down or flake the tests. The
        // `-PinwheelPreview` arg lives in the argument domain, so it survives.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            UIView.setAnimationsEnabled(false)
        }

        Config.colorProvider = DemoColorProvider()
        Config.fontProvider = DemoFontProvider()
    }

    var body: some Scene {
        WindowGroup {
            if let previewID = PinwheelPreview.requestedID {
                PinwheelPreview(previewID, sections: DemoPinwheelSections.all)
            } else {
                PinwheelCatalog {
                    DemoPinwheelSections.tokens
                    DemoPinwheelSections.components
                    DemoPinwheelSections.recyclable
                    DemoPinwheelSections.uikit
                }
            }
        }
    }
}
