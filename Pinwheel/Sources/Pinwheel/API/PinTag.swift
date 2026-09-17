import SwiftUI
import UIKit

public struct PinTag: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public nonisolated init(rawValue: String) { self.rawValue = rawValue }
}

extension PinTag {
    public nonisolated static let swiftUI = PinTag(rawValue: "SwiftUI")
    public nonisolated static let uiKit = PinTag(rawValue: "UIKit")
}
