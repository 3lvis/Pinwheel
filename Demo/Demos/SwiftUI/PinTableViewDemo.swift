import SwiftUI
import Pinwheel

struct PinTableViewDemo: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Account", subtitle: "Signed in", chevron: true) {},
            .text("Notifications", chevron: true) {},
            .text("Privacy & Security", chevron: true) {},
            .text("General", chevron: true) {},
            .text("Wi-Fi", detail: "Home", chevron: true) {},
            .text("Bluetooth", detail: "On", chevron: true) {},
            .toggle("Airplane Mode", isOn: $off),
            .toggle("Low Power Mode", isOn: $off),
            .toggle("Dark Appearance", isOn: $on),
            .text("About", subtitle: "Version 1.0", chevron: true) {},
            .text("Sign out", enabled: false),
        ], onRetry: { state = .loaded })
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = DemoStateFixture.loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = DemoStateFixture.empty }
            PinwheelTweak("Failed") { state = DemoStateFixture.failed }
        }
    }
}
