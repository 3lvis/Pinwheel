import SwiftUI
import Pinwheel

struct PinTableViewExample: SwiftUI.View {
    @SwiftUI.State private var state = "loaded"
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        List {
            switch state {
            case "loading":
                ProgressView("Loading...")
            case "empty":
                ContentUnavailableView("Ready to Move?", systemImage: "tray", description: Text("Kick things off with your first booking."))
            case "failed":
                ContentUnavailableView {
                    Label("Oops!", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("We couldn't load your bookings.")
                } actions: {
                    SwiftUI.Button("Retry") {
                        state = "loading"
                    }
                }
            default:
                PinLabel("Only title", style: .body)
                VStack(alignment: .leading) {
                    PinLabel("Title and subtitle", style: .body)
                    PinLabel("subtitle", style: .caption, color: PinwheelTheme.Colors.secondaryText)
                }
                HStack {
                    VStack(alignment: .leading) {
                        PinLabel("Title, subtitle and detail", style: .body)
                        PinLabel("subtitle", style: .caption, color: PinwheelTheme.Colors.secondaryText)
                    }
                    Spacer()
                    PinLabel("Detail text", style: .body, color: PinwheelTheme.Colors.secondaryText)
                }
                HStack {
                    PinLabel("Has chevron", style: .body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                PinLabel("Is disabled", style: .body, color: PinwheelTheme.Colors.secondaryText)
                Toggle("Off", isOn: $off)
                Toggle("On", isOn: $on)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = "loading" }
            PinwheelTweak("Loaded") { state = "loaded" }
            PinwheelTweak("Empty") { state = "empty" }
            PinwheelTweak("Failed") { state = "failed" }
        }
    }
}
