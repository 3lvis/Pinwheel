import SwiftUI

public struct PinButton: SwiftUI.View {
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
    private let systemImage: String?
    private let action: () -> Void
    private var style: Style = .primary
    private var typography: PinTextStyle = .subtitleSemibold
    private var isLoading: Bool = false
    private var isFullWidth: Bool = false

    @SwiftUI.State private var tapCount = 0
    @Environment(\.pinwheelTheme) private var theme

    public init(
        _ title: String? = nil,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public func style(_ style: Style) -> PinButton {
        var copy = self
        copy.style = style
        return copy
    }

    public func font(_ style: PinTextStyle) -> PinButton {
        var copy = self
        copy.typography = style
        return copy
    }

    public func fullWidth(_ isFullWidth: Bool = true) -> PinButton {
        var copy = self
        copy.isFullWidth = isFullWidth
        return copy
    }

    public func loading(_ isLoading: Bool = true) -> PinButton {
        var copy = self
        copy.isLoading = isLoading
        return copy
    }

    public var body: some SwiftUI.View {
        SwiftUI.Button {
            tapCount += 1
            action()
        } label: {
            label
        }
        .buttonStyle(PinButtonStyle(style: style, hasTitle: title != nil, isFullWidth: isFullWidth))
        .sensoryFeedback(.impact(weight: style.isPrimary ? .medium : .light), trigger: tapCount)
    }

    @ViewBuilder
    private var label: some SwiftUI.View {
        HStack(spacing: .spacing2) {
            if let title {
                Text(title)
                    .font(typography.font(in: theme))
                    .underline(style.isTertiary)
                    .lineLimit(1)
            }

            if let systemImage {
                Image(systemName: systemImage)
                    .font(typography.font(in: theme))
            }

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}

private struct PinButtonStyle: SwiftUI.ButtonStyle {
    let style: PinButton.Style
    let hasTitle: Bool
    let isFullWidth: Bool

    func makeBody(configuration: Configuration) -> some SwiftUI.View {
        Container(configuration: configuration, style: style, hasTitle: hasTitle, isFullWidth: isFullWidth)
    }

    private struct Container: SwiftUI.View {
        let configuration: Configuration
        let style: PinButton.Style
        let hasTitle: Bool
        let isFullWidth: Bool

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.pinwheelTheme) private var theme

        var body: some SwiftUI.View {
            configuration.label
                .foregroundStyle(foreground)
                .tint(foreground)
                .padding(.vertical, .spacing3)
                .padding(.horizontal, .spacing4)
                .frame(minWidth: hasTitle ? 100 : nil)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .frame(minHeight: .minimumControlHeight)
                .background {
                    if let background {
                        theme.buttonShape.shape.fill(background)
                    }
                }
                .contentShape(theme.buttonShape.shape)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }

        private var foreground: SwiftUI.Color {
            switch style {
            case .primary:
                // The label sits on the action-colored fill, so it's the surface token; hard-coding white renders invisible on a pale action color.
                return .primaryBackground
            case .secondary:
                return isEnabled ? .primaryText : .tertiaryText
            case .tertiary:
                return isEnabled ? .secondaryText : .tertiaryText
            case .custom(let text, _):
                return isEnabled ? text : text.opacity(0.5)
            }
        }

        private var background: SwiftUI.Color? {
            switch style {
            case .primary:
                return isEnabled ? .actionText : .actionBackground
            case .secondary:
                return .secondaryBackground
            case .tertiary:
                return nil
            case .custom(_, let background):
                return isEnabled ? background : background.opacity(0.5)
            }
        }
    }
}
