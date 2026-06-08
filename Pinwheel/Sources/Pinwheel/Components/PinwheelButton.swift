import SwiftUI

/// SwiftUI-native counterpart of the UIKit `Button`. Renders a pill that hugs its
/// content, with the same styles, loading spinner, symbol support and press feedback.
public struct PinwheelButton: SwiftUI.View {
    public enum Style: Equatable {
        case primary
        case secondary
        case tertiary
        case custom(text: SwiftUI.Color, background: SwiftUI.Color)

        var isPrimary: Bool {
            if case .primary = self { return true }
            return false
        }

        var isTertiary: Bool {
            if case .tertiary = self { return true }
            return false
        }
    }

    private let title: String?
    private let symbol: String?
    private let style: Style
    private let font: SwiftUI.Font
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        _ title: String? = nil,
        symbol: String? = nil,
        style: Style = .primary,
        font: SwiftUI.Font = PinwheelTheme.Typography.subtitleSemibold,
        isLoading: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.symbol = symbol
        self.style = style
        self.font = font
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            label
        }
        .buttonStyle(PinwheelButtonStyle(style: style, hasTitle: title != nil))
    }

    @ViewBuilder
    private var label: some SwiftUI.View {
        HStack(spacing: .spacingS) {
            if let title {
                Text(title)
                    .font(font)
                    .underline(style.isTertiary)
                    .lineLimit(1)
            }

            if let symbol {
                Image(systemName: symbol)
                    .font(font)
            }

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}

private struct PinwheelButtonStyle: SwiftUI.ButtonStyle {
    let style: PinwheelButton.Style
    let hasTitle: Bool

    func makeBody(configuration: Configuration) -> some SwiftUI.View {
        Container(configuration: configuration, style: style, hasTitle: hasTitle)
    }

    private struct Container: SwiftUI.View {
        let configuration: Configuration
        let style: PinwheelButton.Style
        let hasTitle: Bool

        @Environment(\.isEnabled) private var isEnabled

        var body: some SwiftUI.View {
            configuration.label
                .foregroundStyle(foreground)
                .tint(foreground)
                .padding(.vertical, .spacingM)
                .padding(.horizontal, .spacingL)
                .frame(minWidth: hasTitle ? 100 : nil)
                .background {
                    if let background {
                        RoundedRectangle(cornerRadius: .spacingM, style: .continuous)
                            .fill(background)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: .spacingM, style: .continuous))
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }

        private var foreground: SwiftUI.Color {
            switch style {
            case .primary:
                // White reads correctly on the action color in light and dark.
                return .white
            case .secondary:
                return isEnabled ? PinwheelTheme.Colors.primaryText : PinwheelTheme.Colors.tertiaryText
            case .tertiary:
                return isEnabled ? PinwheelTheme.Colors.secondaryText : PinwheelTheme.Colors.tertiaryText
            case .custom(let text, _):
                return isEnabled ? text : text.opacity(0.5)
            }
        }

        private var background: SwiftUI.Color? {
            switch style {
            case .primary:
                return isEnabled ? PinwheelTheme.Colors.actionText : PinwheelTheme.Colors.actionBackground
            case .secondary:
                return PinwheelTheme.Colors.secondaryBackground
            case .tertiary:
                return nil
            case .custom(_, let background):
                return isEnabled ? background : background.opacity(0.5)
            }
        }
    }
}
