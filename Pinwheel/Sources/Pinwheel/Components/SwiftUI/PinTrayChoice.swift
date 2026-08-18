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
            }
            .padding(.horizontal, .spacing3)
            .frame(maxWidth: .infinity, minHeight: .minimumControlHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .radiusM)
                    .fill(isChosen ? Color.secondaryBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                    .strokeBorder(isChosen ? Color.secondaryText : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChosen ? [.isSelected] : [])
        .accessibilityIdentifier("pinwheel.tray.choice.\(label)")
    }
}
