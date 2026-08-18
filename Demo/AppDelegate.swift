import SwiftUI
import UIKit
import Pinwheel

@main
struct DemoApp: App {
    init() {
        // -PinwheelPreview lives in the argument domain, so it survives the clear.
        if ProcessInfo.processInfo.arguments.contains("-UITestingNoAnimations") {
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            UIView.setAnimationsEnabled(false)
        }

        PinwheelRecorder.start()

        if FigmaCatalog.isManifestDump {
            FigmaCatalog.dumpManifest()
        }

    }

    var body: some Scene {
        WindowGroup {
            if let captureID = FigmaCatalog.requestedCaptureID {
                FigmaCaptureSweepView(id: captureID)
            } else if let previewID = PinwheelPreview.requestedID {
                PinwheelPreview(previewID, sections: DemoPinwheelSections.all, themes: DemoThemes.all)
            } else {
                PinwheelCatalog(themes: DemoThemes.all) {
                    DemoPinwheelSections.tokens
                    DemoPinwheelSections.components
                    DemoPinwheelSections.screens
                }
                .environment(\.pinCaptureSink) { FigmaCatalog.autoPush(id: $0) }
            }
        }
    }
}
