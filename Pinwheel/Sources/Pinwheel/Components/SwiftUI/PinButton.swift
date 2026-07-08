import SwiftUI

public struct PinButton: SwiftUI.View {
    public enum Style: Equatable, PinFillToken, PinTextColorToken {
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

        var fillToken: PinColorToken? {
            switch self {
            case .primary: return .actionText
            case .secondary: return .secondaryBackground
            case .tertiary, .custom: return nil
            }
        }

        var textColorToken: PinColorToken? {
            switch self {
            case .primary: return .primaryBackground
            case .secondary: return .primaryText
            case .tertiary: return .secondaryText
            case .custom: return nil
            }
        }

        public var captureFillToken: String? { fillToken?.rawValue }
        public var captureTextColorToken: String? { textColorToken?.rawValue }

        public var captureFillColor: SwiftUI.Color? {
            if case let .custom(_, background) = self { return background }
            return nil
        }
        public var captureTextColor: SwiftUI.Color? {
            if case let .custom(text, _) = self { return text }
            return nil
        }

        var captureVariant: String {
            switch self {
            case .primary: return "primary"
            case .secondary: return "secondary"
            case .tertiary: return "tertiary"
            case .custom: return "custom"
            }
        }
    }

    public static let minTitledWidth: CGFloat = 100

    private let title: String?
    private let systemImage: String?
    private let action: () -> Void
    private var style: Style = .primary
    private var typography: PinTextStyle = .subtitleSemibold
    private var isLoading: Bool = false

    @SwiftUI.State private var tapCount = 0
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.pinCapturing) private var pinCapturing

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

    private var captureForegroundColor: SwiftUI.Color {
        if case let .custom(text, _) = style { return text }
        return style.textColorToken?.color ?? .primaryText
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
                if pinCapturing {
                    Image(systemName: systemImage)
                        .font(typography.font)
                        .foregroundStyle(captureForegroundColor)
                } else {
                    Image(systemName: systemImage)
                        .font(typography.font)
                }
            }

            if isLoading {
                if pinCapturing {
                    CaptureSpinner()
                        .foregroundStyle(captureForegroundColor)
                } else {
                    ProgressView().controlSize(.small)
                }
            }
        }
    }
}

// A .rotationEffect per spoke loses its rotation in the captured frame, so all spokes are drawn in one Path.
private struct CaptureSpinner: SwiftUI.View {
    var body: some SwiftUI.View {
        SpinnerShape().frame(width: 15, height: 15)
    }
}

private struct SpinnerShape: Shape {
    private let spokes = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for index in 0..<spokes {
            let spoke = Path(roundedRect: CGRect(x: -1, y: -rect.height / 2, width: 2, height: rect.height / 2.8), cornerRadius: 1)
            let rotate = CGAffineTransform(rotationAngle: Double(index) / Double(spokes) * 2 * .pi)
            path.addPath(spoke.applying(rotate).applying(CGAffineTransform(translationX: center.x, y: center.y)))
        }
        return path
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
                .frame(minWidth: hasTitle ? PinButton.minTitledWidth : nil)
                .background {
                    if let background {
                        RoundedRectangle(cornerRadius: .radiusM, style: .continuous)
                            .fill(background)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: .radiusM, style: .continuous))
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }

        // The label sits on the action-colored fill, so it's the surface token; hard-coding white renders invisible on a pale action color.
        private var foreground: SwiftUI.Color {
            if case .custom(let text, _) = style { return isEnabled ? text : text.opacity(0.5) }
            guard let token = style.textColorToken else { return .primaryText }
            if !isEnabled && style != .primary { return .tertiaryText }
            return token.color
        }

        private var background: SwiftUI.Color? {
            if case .custom(_, let background) = style { return isEnabled ? background : background.opacity(0.5) }
            guard let token = style.fillToken else { return nil }
            if !isEnabled && style == .primary { return .actionBackground }
            return token.color
        }
    }
}
