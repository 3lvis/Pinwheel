import SwiftUI

public struct PinStepper: SwiftUI.View {
    private let value: Int
    private var onDecrement: () -> Void = {}
    private var onIncrement: () -> Void = {}

    @Environment(\.pinwheelTheme) private var theme

    public init(value: Int) {
        self.value = value
    }

    public func onDecrement(_ action: @escaping () -> Void) -> PinStepper {
        var copy = self
        copy.onDecrement = action
        return copy
    }

    public func onIncrement(_ action: @escaping () -> Void) -> PinStepper {
        var copy = self
        copy.onIncrement = action
        return copy
    }

    public var body: some SwiftUI.View {
        HStack(spacing: .spacing3) {
            SwiftUI.Button(action: onDecrement) { Image(systemName: "minus") }
            PinLabel("\(value)").font(.body).frame(minWidth: 20)
            SwiftUI.Button(action: onIncrement) { Image(systemName: "plus") }
        }
        .font(PinTextStyle.body.font(in: theme))
        .foregroundStyle(.actionText)
        .padding(.horizontal, .spacing3)
        .padding(.vertical, .spacing2)
        .overlay(Capsule().stroke(.tertiaryText, lineWidth: 1))
    }
}
