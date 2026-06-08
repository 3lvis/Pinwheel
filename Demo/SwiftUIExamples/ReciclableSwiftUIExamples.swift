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
                PinLabel("Only title")
                VStack(alignment: .leading) {
                    PinLabel("Title and subtitle")
                    PinLabel("subtitle").font(.caption).color(.secondary)
                }
                HStack {
                    VStack(alignment: .leading) {
                        PinLabel("Title, subtitle and detail")
                        PinLabel("subtitle").font(.caption).color(.secondary)
                    }
                    Spacer()
                    PinLabel("Detail text").color(.secondary)
                }
                HStack {
                    PinLabel("Has chevron")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                PinLabel("Is disabled").color(.secondary)
                Toggle(isOn: $off) { PinLabel("Off") }
                Toggle(isOn: $on) { PinLabel("On") }
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
