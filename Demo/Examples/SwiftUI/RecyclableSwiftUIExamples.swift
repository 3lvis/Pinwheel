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
            .text("Title and detail", detail: "Detail text"),
            .text("Is disabled", enabled: false),
            .text("Has chevron", chevron: true) {},
            .toggle("Off", isOn: $off),
            .toggle("On", isOn: $on),
            .toggle("Disabled", enabled: false, isOn: $on),
        ], onRetry: { state = .loaded })
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = DemoStateFixture.loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = DemoStateFixture.empty }
            PinwheelTweak("Failed") { state = DemoStateFixture.failed }
        }
    }
}
