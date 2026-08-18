import SwiftUI

/// A paragraph in a tray. Leading unless `centred()`.
public struct PinTrayText: SwiftUI.View {
    private let text: String
    private var isCentred = false

    public init(_ text: String) {
        self.text = text
    }

    public func centred() -> PinTrayText {
        var copy = self
        copy.isCentred = true
        return copy
    }

    public var body: some SwiftUI.View {
        PinLabel(text)
            .color(.secondary)
            .multilineTextAlignment(isCentred ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: isCentred ? .center : .leading)
    }
}
