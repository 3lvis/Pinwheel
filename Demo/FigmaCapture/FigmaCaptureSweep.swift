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

    // The capture-on-view sink: the catalog hands us the displayed component; we build its IR and
    // push it to the serve — so running the app and looking at a component refreshes it, no script.
    static func autoPush(id: String, captured: [PinCapturedComponent], proxy: GeometryProxy) {
        guard let entry = entry(id: id) else { return }
        FigmaCaptureEngine.capture(name: entry.title, captured: captured, proxy: proxy) { document in
            FigmaCaptureFile.pushCatalog(id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, document: document)
        }
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
    @SwiftUI.State private var pushed = false

    var body: some SwiftUI.View {
        Color.clear.onAppear {
            guard !pushed, let entry = FigmaCatalog.entry(id: id) else { return }
            pushed = true
            // Read the rendered DisplayList off a hosted copy — no markers in the view.
            guard let document = PinDisplayListCapture.document(
                entry.item.swiftUIView(), name: entry.title, size: CGSize(width: 402, height: 1600)
            ) else { return }
            FigmaCaptureFile.pushCatalog(
                id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, document: document
            )
        }
    }
}
