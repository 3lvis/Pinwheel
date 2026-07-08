import SwiftUI

public extension SwiftUI.View {
    func pinConcentricContainer(cornerRadius: CGFloat = .radiusM) -> some SwiftUI.View {
        modifier(PinConcentricContainer(cornerRadius: cornerRadius))
    }

    // `inset` is used only below iOS 26 (which can't measure it); pass the inset the content is actually laid out at.
    func pinConcentricBackground(_ token: PinColorToken, inset: CGFloat) -> some SwiftUI.View {
        modifier(PinConcentricBackground(token: token, inset: inset))
    }
}

private struct PinContainerCornerRadiusKey: EnvironmentKey {
    static let defaultValue: CGFloat = .radiusM
}

private extension EnvironmentValues {
    var pinContainerCornerRadius: CGFloat {
        get { self[PinContainerCornerRadiusKey.self] }
        set { self[PinContainerCornerRadiusKey.self] = newValue }
    }
}

private struct PinConcentricContainer: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some SwiftUI.View {
        reference(content).environment(\.pinContainerCornerRadius, cornerRadius)
    }

    @ViewBuilder
    private func reference(_ content: Content) -> some SwiftUI.View {
        if #available(iOS 26, *) {
            content.containerShape(.rect(cornerRadius: cornerRadius))
        } else {
            content
        }
    }
}

private struct PinConcentricBackground: ViewModifier {
    let token: PinColorToken
    let inset: CGFloat

    @Environment(\.pinContainerCornerRadius) private var containerCornerRadius

    func body(content: Content) -> some SwiftUI.View {
        if #available(iOS 26, *) {
            content.background(token.color, in: ConcentricRectangle())
        } else {
            content.background(token.color, in: .rect(cornerRadius: max(containerCornerRadius - inset, 0), style: .continuous))
        }
    }
}
