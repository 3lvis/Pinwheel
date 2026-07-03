import SwiftUI

/// A color token that knows its own name. Components map to a token *once* (for rendering);
/// its `rawValue` is the capture name, so there's no parallel name mapping to keep in sync.
public enum PinColorToken: String, CaseIterable {
    case primaryText
    case secondaryText
    case tertiaryText
    case actionText
    case criticalText
    case primaryBackground
    case secondaryBackground
    case actionBackground
    case criticalBackground

    public var color: Color {
        switch self {
        case .primaryText: return .primaryText
        case .secondaryText: return .secondaryText
        case .tertiaryText: return .tertiaryText
        case .actionText: return .actionText
        case .criticalText: return .criticalText
        case .primaryBackground: return .primaryBackground
        case .secondaryBackground: return .secondaryBackground
        case .actionBackground: return .actionBackground
        case .criticalBackground: return .criticalBackground
        }
    }
}
