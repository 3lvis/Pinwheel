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

// Hosts the component full-screen and captures the DisplayList off that *live* on-screen render — not a
// throwaway off-screen copy. Heavy UIKit controls (slider/segmented/progress) only populate the
// DisplayList once actually rendered, and an off-screen duplicate is throttled in a batch and drops them;
// the real render is always complete. Captured once per appearance (the host's own light/dark override),
// then merged, so every control and colour adapts from the same reliable render.
struct FigmaCaptureSweepView: SwiftUI.View {
    let id: String

    var body: some SwiftUI.View {
        if let entry = FigmaCatalog.entry(id: id) {
            LiveCaptureHost(entry: entry).ignoresSafeArea()
        } else {
            Color.clear
        }
    }
}

private struct LiveCaptureHost: UIViewControllerRepresentable {
    let entry: FigmaCatalogEntry

    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        container.view.backgroundColor = .clear
        let host = UIHostingController(rootView: AnyView(entry.item.swiftUIView().environment(\.pinCapturing, true)))
        container.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(host.view)
        // Host at the taller of the screen and the content's own height. Content taller than the screen
        // (a long button list) would otherwise be clamped to the window and its below-the-fold rows would
        // never enter the DisplayList — the reflected tree then outnumbers the rendered leaves, the zip
        // fails, and the whole screen drops to the containment fallback (losing every pill). A short screen
        // stays at screen height so its controls paint on-window (drawHierarchy only sees the visible
        // window) and a centered empty state still centers.
        let width = FigmaCatalog.captureCanvas.width
        let screenHeight = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen.bounds.height ?? FigmaCatalog.captureCanvas.height
        let contentHeight = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        // Fixed capture width so the IR matches the design regardless of the device the sim happens to be.
        NSLayoutConstraint.activate([
            host.view.widthAnchor.constraint(equalToConstant: width),
            host.view.centerXAnchor.constraint(equalTo: container.view.centerXAnchor),
            host.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            host.view.heightAnchor.constraint(equalToConstant: max(screenHeight, contentHeight))
        ])
        host.didMove(toParent: container)
        // Capture once the component has painted on-screen (a UISwitch renders its knob only on-window).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { capture(host: host) }
        return container
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    private func capture(host: UIViewController) {
        let size = host.view.bounds.size
        host.view.layoutIfNeeded()
        // Capture a single document in the *simulator's* current appearance — UIKit controls only render
        // in the sim's appearance, so the sweep runs twice (sim light, then sim dark) and merges the two.
        guard let document = PinDisplayListCapture.document(
            entry.item.swiftUIView(), name: entry.title, size: size, screenHeight: FigmaCatalog.oneScreen, liveHost: host.view
        ) else { return }
        let version = PinCaptureVersions.shared.record(id: entry.id, document: document)
        FigmaCaptureFile.pushCatalog(
            app: FigmaCatalog.appName, id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, version: version, document: document
        )
    }
}
