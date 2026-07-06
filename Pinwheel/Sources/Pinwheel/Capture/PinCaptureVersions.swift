import Foundation
import CryptoKit

// The version a component's capture is on — a plain integer the app owns, bumping by one only when the
// captured structure actually changes. Persisted so it survives launches (the sweep runs one app launch
// per component). The catalog pill reads it and the pushed catalog carries it, so the number the plugin
// lists and the number the app shows are the same — a designer can tell when an import is behind.
@MainActor
@Observable
public final class PinCaptureVersions {
    public static let shared = PinCaptureVersions()

    private struct Entry: Codable { var version: Int; var hash: String }
    private var entries: [String: Entry]
    private let storageKey = "PinCaptureVersions"

    private init() {
        entries = UserDefaults.standard.data(forKey: storageKey)
            .flatMap { try? JSONDecoder().decode([String: Entry].self, from: $0) } ?? [:]
    }

    public func version(for id: String) -> Int? { entries[id]?.version }

    /// Records this capture and returns its version — unchanged when the structure matches the last
    /// recorded one, incremented by one when it differs.
    @discardableResult
    public func record(id: String, document: FigmaDocument) -> Int {
        let hash = Self.structureHash(document)
        let previous = entries[id]
        let version = (previous?.hash == hash) ? (previous?.version ?? 1) : (previous?.version ?? 0) + 1
        entries[id] = Entry(version: version, hash: hash)
        if let data = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(data, forKey: storageKey) }
        return version
    }

    // Images are excluded: a control's PNG varies with the render context (playground vs full-screen
    // sweep) without being a design change, so hashing them would churn the number. Structure, text,
    // and tokens are what a real update changes.
    private static func structureHash(_ document: FigmaDocument) -> String {
        guard let data = try? JSONEncoder().encode(document),
              let object = try? JSONSerialization.jsonObject(with: data) else { return "" }
        guard let normalized = try? JSONSerialization.data(withJSONObject: stripImages(object), options: [.sortedKeys]) else { return "" }
        return SHA256.hash(data: normalized).map { String(format: "%02x", $0) }.joined()
    }

    private static func stripImages(_ value: Any) -> Any {
        if var dictionary = value as? [String: Any] {
            dictionary.removeValue(forKey: "image")
            dictionary.removeValue(forKey: "imageDark")
            return dictionary.mapValues(stripImages)
        }
        if let array = value as? [Any] { return array.map(stripImages) }
        return value
    }
}
