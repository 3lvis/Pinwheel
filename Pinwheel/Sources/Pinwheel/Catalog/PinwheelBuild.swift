import Foundation

/// Which binary is running, read from the binary itself so it cannot describe a different one.
public enum PinwheelBuild {
    public static let builtAt: Date? = {
        guard let executable = Bundle.main.executableURL else { return nil }
        return try? FileManager.default
            .attributesOfItem(atPath: executable.path)[.modificationDate] as? Date
    }()

    /// The short form to hand over in conversation, so a person can match what they are holding.
    public static var label: String {
        guard let builtAt else { return "build unknown" }
        let clock = DateFormatter()
        clock.dateFormat = "HHmm"
        return "build \(clock.string(from: builtAt))"
    }

    public static var detail: String {
        guard let builtAt else { return "no build date" }
        let stamp = DateFormatter()
        stamp.dateFormat = "d MMM, HH:mm:ss"
        return stamp.string(from: builtAt)
    }
}
