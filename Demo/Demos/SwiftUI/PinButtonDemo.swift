import SwiftUI
import Pinwheel

struct PinButtonDemo: SwiftUI.View {
    @SwiftUI.State private var isLoading = false
    @SwiftUI.State private var isDisabled = false

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingM) {
                PinButton("Press me") {}
                    .disabled(isDisabled)

                PinButton("Save") {}
                    .disabled(true)

                PinButton("Saving") {}
                    .loading()

                PinButton("Saving") {}
                    .loading()
                    .disabled(true)

                PinButton("Continue", systemImage: "arrow.right") {}

                PinButton(systemImage: "arrow.right") {}

                PinButton("Long toggle loading") {
                    isLoading.toggle()
                }
                .style(.secondary)
                .loading(isLoading)

                PinButton("Disabled") {}
                    .style(.secondary)
                    .disabled(true)

                PinButton("Update titles") {}
                    .style(.tertiary)

                PinButton("Disabled") {}
                    .style(.tertiary)
                    .disabled(true)

                PinButton("Custom") {}
                    .font(.caption)
                    .style(.custom(text: .green, background: .red))

                PinButton("Custom") {}
                    .font(.caption)
                    .style(.custom(text: .green, background: .red))
                    .disabled(true)
            }
            .padding(.vertical, .spacingXXL)
            .frame(maxWidth: .infinity)
        }
        .background(.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}
