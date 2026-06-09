import SwiftUI

/// SwiftUI-native pill button: themed styles, an optional SF Symbol, a loading
/// state, and press feedback. Mirrors SwiftUI's `Button(_:systemImage:action:)`;
/// visual style and loading are chained modifiers, like SwiftUI's `.buttonStyle`.
///
/// ```swift
/// PinButton("Save") { save() }
/// PinButton("Continue", systemImage: "arrow.right") { go() }.style(.secondary)
/// PinButton("Saving") { }.loading(isSaving)
/// PinButton(systemImage: "arrow.right") { }            // symbol-only
/// ```
///
/// The button owns its type style (`subtitleSemibold`); `.custom` is the escape
/// hatch for one-off colors.
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

    @SwiftUI.State private var tapCount = 0

    public init(
        _ title: String? = nil,
        systemImage: String? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    /// Sets the visual style (default `.primary`).
    public func style(_ style: Style) -> PinButton {
        var copy = self
        copy.style = style
        return copy
    }

    /// Sets the title/symbol typography (default `.subtitleSemibold`). Takes a
    /// themed `PinTextStyle`, not a raw `Font`, so it stays on the design system.
    public func font(_ style: PinTextStyle) -> PinButton {
        var copy = self
        copy.typography = style
        return copy
    }

    /// Shows a loading spinner alongside the content (default `true`).
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
        .buttonStyle(PinButtonStyle(style: style, hasTitle: title != nil))
        .sensoryFeedback(.impact(weight: style.isPrimary ? .medium : .light), trigger: tapCount)
    }

    @ViewBuilder
    private var label: some SwiftUI.View {
        HStack(spacing: .spacingS) {
            if let title {
                Text(title)
                    .font(typography.font)
                    .underline(style.isTertiary)
                    .lineLimit(1)
            }

            if let systemImage {
                Image(systemName: systemImage)
                    .font(typography.font)
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

    func makeBody(configuration: Configuration) -> some SwiftUI.View {
        Container(configuration: configuration, style: style, hasTitle: hasTitle)
    }

    private struct Container: SwiftUI.View {
        let configuration: Configuration
        let style: PinButton.Style
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
                // The label sits on the action-colored fill, so it's the surface
                // token — the inverse of the FAB (primaryBackground surface +
                // actionText accent). Never hard-code white: a provider with a
                // pale action color would render invisible text.
                return PinwheelTheme.Colors.primaryBackground
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
