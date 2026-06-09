import SwiftUI
import Pinwheel

struct PinLabelExample: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            PinLabel("Title").font(.title)
            PinLabel("Subtitle").font(.subtitle)
            PinLabel("Body")
            PinLabel("Footnote").font(.footnote)
            PinLabel("Caption").font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingL)
        .background(PinwheelTheme.Colors.primaryBackground)
    }
}

struct PinTweakableExample: SwiftUI.View {
    @SwiftUI.State private var selection = "Tap the settings button and choose an option."
    @SwiftUI.State private var isOn = false

    var body: some SwiftUI.View {
        PinLabel(selection)
            .multilineTextAlignment(.center)
            .padding(.spacingXXL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PinwheelTheme.Colors.primaryBackground)
            .pinwheelTweaks {
                PinwheelTweak("Option 1") {
                    selection = "Chosen Option 1"
                }

                PinwheelTweak("Option 2", description: "Description 2") {
                    selection = "Chosen Option 2"
                }

                PinwheelTweak("Option 3", description: "Toggle-backed option", isOn: $isOn)
            }
            .onChange(of: isOn) { _, value in
                selection = "Option 3 is \(value ? "on" : "off")"
            }
    }
}

struct PinButtonExample: SwiftUI.View {
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
        .background(PinwheelTheme.Colors.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}

struct PinStateViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinState = DemoStateFixture.empty

    var body: some SwiftUI.View {
        PinStateView(state) {
            state = DemoStateFixture.loading
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PinwheelTheme.Colors.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = DemoStateFixture.loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = DemoStateFixture.empty }
            PinwheelTweak("Failed") { state = DemoStateFixture.failed }
        }
    }
}
