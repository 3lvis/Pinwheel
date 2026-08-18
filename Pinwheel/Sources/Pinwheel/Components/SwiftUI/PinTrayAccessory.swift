import SwiftUI

/// What a tray stands at the bottom of the card. The case is the answer, so nothing carries a flag
/// beside a view that could disagree with it.
enum PinTrayAccessory {
    case nothing
    case floating(AnyView)
    case commitButton(AnyView)

    var isCommitButton: Bool {
        if case .commitButton = self { return true }
        return false
    }

    var leaf: AnyView? {
        switch self {
        case .nothing: nil
        case .floating(let leaf), .commitButton(let leaf): leaf
        }
    }
}
