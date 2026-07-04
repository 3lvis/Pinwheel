import SwiftUI
import Pinwheel

// The catalog half of the capture system: render one catalog item in isolation, wrapped in a
// capture host, and push its IR to the local serve keyed by item id. A sweep launches the app
// once per id (`-PinwheelCapture <id>`); the serve accumulates the per-item captures into a
// manifest the plugin lists. `-PinwheelManifest` dumps the catalog skeleton so the sweep script
// can enumerate ids from the registry itself, not by grepping source.

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

    // The id requested for a capture-sweep launch (`-PinwheelCapture <id>`), else nil.
    static var requestedCaptureID: String? {
        UserDefaults.standard.string(forKey: "PinwheelCapture").flatMap { $0.isEmpty ? nil : $0 }
    }

    static var isManifestDump: Bool {
        ProcessInfo.processInfo.arguments.contains("-PinwheelManifest")
    }

    // Writes the catalog skeleton to Documents so the sweep script reads ids from the registry.
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

    var body: some SwiftUI.View {
        if let entry = FigmaCatalog.entry(id: id) {
            FigmaCaptureHost(name: entry.title, content: entry.item.swiftUIView()) { document in
                FigmaCaptureFile.pushCatalog(
                    id: entry.id, title: entry.title, section: entry.section, tags: entry.tags,
                    document: document
                )
            }
        } else {
            Color.clear
        }
    }
}
