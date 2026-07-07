import SwiftUI
import Pinwheel

// Renders one catalog item and pushes its capture to the serve, keyed by id — the per-item half of
// the catalog sweep (`Scripts/sweep.sh --capture`).

struct FigmaCatalogEntry {
    let id: String
    let title: String
    let section: String
    let tags: [String]
    let item: PinwheelItem
}

@MainActor
enum FigmaCatalog {
    // A tall render canvas so scrolling demos lay out fully, plus the one-screen height a full-screen
    // component centers into: the iPhone 17 content area between the plugin's 62pt status bar and 34pt
    // home indicator (874 − 62 − 34).
    static let appName = "Pinwheel iOS"
    static let captureCanvas = CGSize(width: 402, height: 1600)
    static let oneScreen: CGFloat = 778

    static var entries: [FigmaCatalogEntry] {
        DemoPinwheelSections.all.flatMap { section in
            // UIKit-hosted views capture only as an opaque platform-view snapshot, not editable Figma
            // nodes — keep them out of the capture catalog until that's decomposed. The app's own
            // catalog still shows them.
            section.items.filter { !$0.tags.contains(.uiKit) }.map { item in
                FigmaCatalogEntry(
                    id: item.id, title: item.title, section: section.title,
                    tags: item.tags.map(\.rawValue), item: item
                )
            }
        }
    }

    static func entry(id: String) -> FigmaCatalogEntry? {
        entries.first { $0.id == id }
    }

    // The capture-on-view sink: the catalog hands us the displayed component; we build its IR and
    // push it to the serve — so running the app and looking at a component refreshes it, no script.
    static func autoPush(id: String, captured: [PinCapturedComponent], proxy: GeometryProxy) {
        // Ignore the marker descriptors — read the DisplayList off a fresh hosted copy so viewing a
        // component in the app pushes the same marker-free IR as the -PinwheelCapture path.
        guard let entry = entry(id: id),
              let document = PinDisplayListCapture.document(entry.item.swiftUIView(), name: entry.title, size: FigmaCatalog.captureCanvas, screenHeight: FigmaCatalog.oneScreen)
        else { return }
        let version = PinCaptureVersions.shared.record(id: entry.id, document: document)
        FigmaCaptureFile.pushCatalog(app: FigmaCatalog.appName, id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, version: version, document: document)
    }

    static var requestedCaptureID: String? {
        UserDefaults.standard.string(forKey: "PinwheelCapture").flatMap { $0.isEmpty ? nil : $0 }
    }

    static var isManifestDump: Bool {
        ProcessInfo.processInfo.arguments.contains("-PinwheelManifest")
    }

    static func dumpManifest() {
        let skeleton = entries.map { ManifestItem(id: $0.id, title: $0.title, section: $0.section, tags: $0.tags) }
        guard let data = try? JSONEncoder().encode(skeleton),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        try? data.write(to: directory.appendingPathComponent("pinwheel-catalog.json"))
    }

    private struct ManifestItem: Encodable {
        let id: String
        let title: String
        let section: String
        let tags: [String]
    }
}

struct FigmaCaptureSweepView: SwiftUI.View {
    let id: String
    @SwiftUI.State private var captureScheme: ColorScheme = .light
    @SwiftUI.State private var lightDocument: FigmaDocument?
    @SwiftUI.State private var pushed = false

    var body: some SwiftUI.View {
        Group {
            if let entry = FigmaCatalog.entry(id: id) { entry.item.swiftUIView() } else { Color.clear }
        }
        // Drives the on-screen appearance so a live UIKit control (a UISwitch's knob only renders on the
        // window) is cropped in the appearance being captured.
        .preferredColorScheme(captureScheme)
        .onAppear { captureLightPass() }
    }

    // A UIKit control only renders its real state on the live window, so its dark variant can't come from
    // the off-screen dark pass — capture the whole screen twice (light, then dark) and graft the dark
    // control crops onto the light document. Off-screen content (colors/symbols/separators) already
    // carries both appearances from `document`'s own light/dark render.
    private func captureLightPass() {
        guard !pushed, let entry = FigmaCatalog.entry(id: id) else { return }
        pushed = true
        // Capture after the component paints on-screen (a UISwitch renders its knob only once on-window).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            lightDocument = capture(entry)
            captureScheme = .dark
            captureDarkPass(entry)
        }
    }

    private func captureDarkPass(_ entry: FigmaCatalogEntry) {
        // Let the dark appearance take effect on-screen before cropping the controls again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard let light = lightDocument, let dark = capture(entry) else { return }
            let document = PinDisplayListCapture.graftingLiveControlDarkImages(onto: light, from: dark)
            let version = PinCaptureVersions.shared.record(id: entry.id, document: document)
            FigmaCaptureFile.pushCatalog(
                app: FigmaCatalog.appName, id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, version: version, document: document
            )
        }
    }

    private func capture(_ entry: FigmaCatalogEntry) -> FigmaDocument? {
        PinDisplayListCapture.document(
            entry.item.swiftUIView(), name: entry.title, size: FigmaCatalog.captureCanvas, screenHeight: FigmaCatalog.oneScreen,
            liveControlsOnScreen: true
        )
    }
}
