import SwiftUI
import UIKit

public struct PinTag: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public nonisolated init(rawValue: String) { self.rawValue = rawValue }
}

public extension PinTag {
    nonisolated static let swiftUI = PinTag(rawValue: "SwiftUI")
    nonisolated static let uiKit = PinTag(rawValue: "UIKit")
}
