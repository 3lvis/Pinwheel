import SwiftUI
import Pinwheel

struct PinSwiftUITableView: SwiftUI.View {
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
                Text("Only title")
                VStack(alignment: .leading) {
                    Text("Title and subtitle")
                    Text("subtitle")
                        .font(.caption)
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Title, subtitle and detail")
                        Text("subtitle")
                            .font(.caption)
                            .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                    }
                    Spacer()
                    Text("Detail text")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                HStack {
                    Text("Has chevron")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
                }
                Text("Is disabled")
                    .foregroundStyle(SwiftUI.Color(uiColor: .secondaryText))
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
