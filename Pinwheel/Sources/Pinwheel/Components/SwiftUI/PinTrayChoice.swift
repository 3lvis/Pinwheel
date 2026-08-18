import SwiftUI

/// One of a set of mutually exclusive options. Choosing applies at once.
public struct PinTrayChoice: SwiftUI.View {
    private let label: String
    private let systemImage: String?
    private let isChosen: Bool
    private let choose: () -> Void

    public init(
        _ label: String,
        systemImage: String? = nil,
        isChosen: Bool,
        choose: @escaping () -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.isChosen = isChosen
        self.choose = choose
    }

    public var body: some SwiftUI.View {
        SwiftUI.Button(action: choose) {
            HStack(spacing: .spacing3) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.primaryText)
                        .frame(width: .spacing6, alignment: .center)
                }
                PinLabel(label)
                Spacer(minLength: .spacing4)
                Image(systemName: "checkmark")
                    .foregroundStyle(.primaryText)
                    .opacity(isChosen ? 1 : 0)
            }
            .padding(.horizontal, .spacing4)
            .frame(minHeight: .minimumControlHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? [.isSelected] : [])
        .accessibilityIdentifier("pinwheel.tray.choice.\(label)")
    }
}
