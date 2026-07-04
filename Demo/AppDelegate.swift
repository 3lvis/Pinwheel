import SwiftUI
import UIKit
import Pinwheel

@main
struct DemoApp: App {
    init() {
        // -UITesting clears persisted state so a prior run's selection can't leak
        // in, and disables animations so presentations don't flake the tests.
        // -PinwheelPreview lives in the argument domain, so it survives the clear.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            UIView.setAnimationsEnabled(false)
        }

        Config.colorProvider = DemoColorProvider()
        Config.fontProvider = DemoFontProvider()

        if FigmaCatalog.isManifestDump {
            FigmaCatalog.dumpManifest()
        }
    }

    var body: some Scene {
        WindowGroup {
            if let captureID = FigmaCatalog.requestedCaptureID {
                FigmaCaptureSweepView(id: captureID)
            } else if let previewID = PinwheelPreview.requestedID {
                PinwheelPreview(previewID, sections: DemoPinwheelSections.all)
            } else {
                PinwheelCatalog {
                    DemoPinwheelSections.tokens
                    DemoPinwheelSections.components
                    DemoPinwheelSections.screens
                }
            }
        }
    }
}
