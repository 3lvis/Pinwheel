import SwiftUI
import Pinwheel

struct PinTableViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Only title"),
            .text("Title and subtitle", subtitle: "subtitle"),
            .text("Title, subtitle and detail", subtitle: "subtitle", detail: "Detail text"),
            .text("Is disabled", enabled: false),
            .text("Has chevron", chevron: true) { state = .loaded },
            .toggle("Off", isOn: $off),
            .toggle("On", isOn: $on),
        ], onRetry: { state = .loaded })
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = .loading(title: "Loading...", subtitle: "Please wait while we fetch your details.") }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = .empty(title: "Ready to Move?", subtitle: "Kick things off with your first booking.") }
            PinwheelTweak("Failed") { state = .failed(title: "Oops!", subtitle: "We couldn't load your bookings.", actionTitle: "Retry") }
        }
    }
}
