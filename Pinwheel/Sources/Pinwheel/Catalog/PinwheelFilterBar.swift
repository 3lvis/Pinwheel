import SwiftUI

struct PinwheelFilterBar: SwiftUI.View {
    let tags: [PinTag]
    @Binding var selectedTag: PinTag?
    let scrolledDistance: CGFloat

    // Height matches the offset so the scrim sits flush below the pill bar.
    private static let scrimHeight: CGFloat = 40
    private static let scrimRampDistance: CGFloat = 24

    private var fadeOpacity: Double {
        Double(min(1, max(0, scrolledDistance) / Self.scrimRampDistance))
    }

    var body: some SwiftUI.View {
        pills
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        PinwheelTheme.Colors.primaryBackground,
                        PinwheelTheme.Colors.primaryBackground.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: Self.scrimHeight)
                .offset(y: Self.scrimHeight)
                .opacity(fadeOpacity)
                .allowsHitTesting(false)
            }
    }

    private var pills: some SwiftUI.View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(tags, id: \.self) { tag in
                    pill(title: tag.rawValue, isSelected: selectedTag == tag) {
                        selectedTag = selectedTag == tag ? nil : tag
                    }
                }
            }
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingS)
        }
        .background(.primaryBackground)
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            PinLabel(title)
                .color(isSelected ? .custom(PinwheelTheme.Colors.primaryBackground) : .action)
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background {
                    if isSelected {
                        Capsule().fill(.actionText)
                    } else {
                        Capsule().strokeBorder(.actionText, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
