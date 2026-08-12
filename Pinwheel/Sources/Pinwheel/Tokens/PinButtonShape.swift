import SwiftUI

public enum PinButtonShape: Sendable, Equatable {
    case rounded
    case capsule

    var shape: AnyShape {
        switch self {
        case .rounded:
            return AnyShape(RoundedRectangle(cornerRadius: .spacingM, style: .continuous))
        case .capsule:
            return AnyShape(Capsule(style: .continuous))
        }
    }
}
