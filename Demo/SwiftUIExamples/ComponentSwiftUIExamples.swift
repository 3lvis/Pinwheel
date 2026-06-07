import SwiftUI
import Pinwheel

struct PinSwiftUILabel: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            Text("Title").font(.title)
            Text("Subtitle").font(.title3)
            Text("Body").font(.body)
            Text("Footnote").font(.footnote)
            Text("Caption").font(.caption)
        }
        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingL)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}

struct PinSwiftUITweakable: SwiftUI.View {
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

struct PinSwiftUIFullscreenView: SwiftUI.View {
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

struct PinSwiftUIButton: SwiftUI.View {
    @SwiftUI.State private var isLoading = false
    @SwiftUI.State private var isDisabled = false

    var body: some SwiftUI.View {
        VStack(spacing: 16) {
            SwiftUI.Button {
                isLoading.toggle()
            } label: {
                SwiftUI.Label(isLoading ? "Saving" : "Save", systemImage: isLoading ? "clock" : "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDisabled)

            SwiftUI.Button("Secondary") {
            }
            .buttonStyle(.bordered)
            .disabled(isDisabled)

            SwiftUI.Button("Destructive", role: .destructive) {
            }
            .buttonStyle(.bordered)
            .disabled(isDisabled)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}

struct PinSwiftUIStateView: SwiftUI.View {
    private enum StateKind: String {
        case loading
        case loaded
        case empty
        case failed
    }

    @SwiftUI.State private var state: StateKind = .loaded

    var body: some SwiftUI.View {
        VStack(spacing: .spacingM) {
            switch state {
            case .loading:
                ProgressView("Loading...")
                    .font(.body)
            case .loaded:
                Text("Loaded")
                    .font(.title.bold())
            case .empty:
                Text("Ready to Move?")
                    .font(.title.bold())
                Text("Kick things off with your first booking.")
                    .font(.body)
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
            case .failed:
                Text("Oops!")
                    .font(.title.bold())
                Text("We couldn't load your bookings.")
                    .font(.body)
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                SwiftUI.Button("Retry") {
                    state = .loading
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.spacingXXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = .loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = .empty }
            PinwheelTweak("Failed") { state = .failed }
        }
    }
}
