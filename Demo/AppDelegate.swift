import SwiftUI
import Pinwheel

@main
struct DemoApp: App {
    init() {
        Config.colorProvider = DemoColorProvider()
        Config.fontProvider = DemoFontProvider()
    }

    var body: some Scene {
        WindowGroup {
            if let previewID = PinwheelPreview.requestedID {
                PinwheelPreview(previewID, sections: DemoPinwheelSections.all)
            } else {
                PinwheelCatalog {
                    DemoPinwheelSections.dna
                    DemoPinwheelSections.components
                    DemoPinwheelSections.reciclable
                    DemoPinwheelSections.uikit
                }
            }
        }
    }
}
