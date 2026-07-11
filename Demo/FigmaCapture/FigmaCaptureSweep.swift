import SwiftUI
import Pinwheel

struct FigmaCatalogEntry {
    let id: String
    let title: String
    let section: String
    let tags: [String]
    let item: PinwheelItem
}

@MainActor
enum FigmaCatalog {
    // oneScreen is the plugin's iPhone 17 content area: 874 − 62pt status bar − 34pt home indicator.
    static let appName = "Pinwheel iOS"
    static let captureCanvas = CGSize(width: 402, height: 1600)
    static let oneScreen: CGFloat = 778

    static var entries: [FigmaCatalogEntry] {
        DemoPinwheelSections.all.flatMap { section in
            section.items.map { item in
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

    static func autoPush(id: String) {
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

// Heavy UIKit controls (slider/segmented/progress) populate the DisplayList only once actually rendered,
// so capture off the live on-screen render; an off-screen duplicate is batch-throttled and drops them.
struct FigmaCaptureSweepView: SwiftUI.View {
    let id: String
    @State private var summary: String?

    var body: some SwiftUI.View {
        if let entry = FigmaCatalog.entry(id: id) {
            LiveCaptureHost(entry: entry) { document in summary = document.captureSummary }
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    // Must ride the outer view, not the hosted content, or it enters the capture itself.
                    if ProcessInfo.processInfo.arguments.contains("-UITesting"), let summary {
                        Text(summary).accessibilityIdentifier("capture.summary").opacity(0.02)
                    }
                }
        } else {
            Color.clear
        }
    }
}

private struct LiveCaptureHost: UIViewControllerRepresentable {
    let entry: FigmaCatalogEntry
    var onCaptured: ((FigmaDocument) -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        container.view.backgroundColor = .clear
        let host = UIHostingController(rootView: AnyView(entry.item.swiftUIView().environment(\.pinCapturing, true)))
        container.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        container.view.addSubview(host.view)
        // Below-the-fold rows never enter the DisplayList if the host is clamped to the window, so size to
        // the taller of screen and content; drawHierarchy only sees the visible window, so keep short
        // content at screen height so its controls still paint on-window.
        let width = FigmaCatalog.captureCanvas.width
        let screenHeight = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen.bounds.height ?? FigmaCatalog.captureCanvas.height
        let contentHeight = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
        NSLayoutConstraint.activate([
            host.view.widthAnchor.constraint(equalToConstant: width),
            host.view.centerXAnchor.constraint(equalTo: container.view.centerXAnchor),
            host.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            host.view.heightAnchor.constraint(equalToConstant: max(screenHeight, contentHeight))
        ])
        host.didMove(toParent: container)
        // A UISwitch renders its knob only on-window, so capture after it has painted on-screen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { capture(host: host) }
        return container
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    private func capture(host: UIViewController) {
        let size = host.view.bounds.size
        host.view.layoutIfNeeded()
        // Route by world, not by trial: a SwiftUI component reads its DisplayList; only a UIKit component
        // walks the real UIView tree (PinUIKitCapture). Trying PinUIKitCapture first for everything lets
        // it intercept a SwiftUI screen — e.g. it grabs a button's spinner views as stray crops and the
        // real pills/text never capture. (UIKit controls render only in the sim's own appearance, so the
        // sweep runs twice — sim light, then dark — and merges the two single-appearance documents.)
        let displayList = { PinDisplayListCapture.document(entry.item.swiftUIView(), name: entry.title, size: size, screenHeight: FigmaCatalog.oneScreen, liveHost: host.view) }
        // A SwiftUI `List` hides its rows behind per-cell hosting views the DisplayList can't see; capture
        // it via the backing-collection walk (nil for non-List SwiftUI screens, so they fall through).
        let listCapture = { PinSwiftUIListCapture.document(name: entry.title, size: size, screenHeight: FigmaCatalog.oneScreen, liveHost: host.view) }
        guard let document = entry.item.isUIKitHosted
            ? (PinUIKitCapture.document(host: host.view, name: entry.title, size: size, screenHeight: FigmaCatalog.oneScreen) ?? displayList())
            : (listCapture() ?? displayList())
        else { return }
        onCaptured?(document)
        let version = PinCaptureVersions.shared.record(id: entry.id, document: document)
        FigmaCaptureFile.pushCatalog(
            app: FigmaCatalog.appName, id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, version: version, document: document
        )
    }
}
