import SwiftUI

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
