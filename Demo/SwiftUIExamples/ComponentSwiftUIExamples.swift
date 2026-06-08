import SwiftUI
import Pinwheel

struct PinLabelExample: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            PinLabel("Title", style: .title)
            PinLabel("Subtitle", style: .subtitle)
            PinLabel("Body", style: .body)
            PinLabel("Footnote", style: .footnote)
            PinLabel("Caption", style: .caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingL)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

struct PinTweakableExample: SwiftUI.View {
    @SwiftUI.State private var selection = "Tap the settings button and choose an option."
    @SwiftUI.State private var isOn = false

    var body: some SwiftUI.View {
        Text(selection)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
            .padding(.spacingXXL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SwiftUI.Color(uiColor: .primaryBackground))
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

struct PinFullscreenViewExample: SwiftUI.View {
    @SwiftUI.State private var text = ""

    var body: some SwiftUI.View {
        VStack(spacing: .spacingM) {
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(SwiftUI.Color(uiColor: .secondaryBackground))
                .frame(minHeight: 180)

            Spacer()

            HStack {
                Text("Left Label")
                Spacer()
                Text("Right Label")
            }
            .font(.body)
            .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        }
        .padding(.spacingM)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
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

                PinButton("Saving", isLoading: true) {}

                PinButton("Saving", isLoading: true) {}
                    .disabled(true)

                PinButton("Continue", symbol: "arrow.right") {}

                PinButton(symbol: "arrow.right") {}

                PinButton("Long toggle loading", style: .secondary, isLoading: isLoading) {
                    isLoading.toggle()
                }

                PinButton("Disabled", style: .secondary) {}
                    .disabled(true)

                PinButton("Update titles", style: .tertiary) {}

                PinButton("Disabled", style: .tertiary) {}
                    .disabled(true)

                PinButton("Custom", style: .custom(text: .green, background: .red), font: PinwheelTheme.Typography.caption) {}

                PinButton("Custom", style: .custom(text: .green, background: .red), font: PinwheelTheme.Typography.caption) {}
                    .disabled(true)
            }
            .padding(.vertical, .spacingXXL)
            .frame(maxWidth: .infinity)
        }
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}

struct PinStateViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinStateView.State = .empty(
        title: "Ready to Move?",
        subtitle: "Kick things off with your first booking."
    )

    var body: some SwiftUI.View {
        PinStateView(state) {
            state = .loading(title: "Loading...", subtitle: "Please wait while we fetch your details.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading") {
                state = .loading(title: "Loading...", subtitle: "Please wait while we fetch your details.")
            }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") {
                state = .empty(title: "Ready to Move?", subtitle: "Kick things off with your first booking.")
            }
            PinwheelTweak("Failed") {
                state = .failed(title: "Oops!", subtitle: "We couldn't load your bookings.", actionTitle: "Retry")
            }
        }
    }
}
