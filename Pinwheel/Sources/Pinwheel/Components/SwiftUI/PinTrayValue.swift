import SwiftUI

/// A row showing what is currently chosen, which opens the tray that changes it.
public struct PinTrayValue: SwiftUI.View {
    private let label: String
    private let value: String
    private let open: () -> Void

    public init(_ label: String, value: String, open: @escaping () -> Void) {
        self.label = label
        self.value = value
        self.open = open
    }

    public var body: some SwiftUI.View {
        SwiftUI.Button(action: open) {
            HStack(spacing: .spacing2) {
                PinLabel(label).color(.secondary)
                Spacer(minLength: .spacing4)
                PinLabel(value).font(.bodySemibold)
                Image(systemName: "chevron.forward")
                    .imageScale(.small)
                    .foregroundStyle(.secondaryText)
            }
            .padding(.horizontal, .spacing4)
            .frame(minHeight: .minimumControlHeight)
            .background(RoundedRectangle(cornerRadius: .radiusM).fill(Color.secondaryBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pinwheel.tray.value.\(label)")
    }
}
