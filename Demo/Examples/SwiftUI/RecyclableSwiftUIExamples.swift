import SwiftUI
import Pinwheel

struct PinTableViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Account", icon: "person.crop.circle.fill", subtitle: "Signed in", chevron: true) {},
            .text("Notifications", icon: "bell.badge.fill", chevron: true) {},
            .text("Privacy & Security", icon: "lock.fill", chevron: true) {},
            .text("General", icon: "gearshape.fill", chevron: true) {},
            .text("Wi-Fi", icon: "wifi", detail: "Home", chevron: true) {},
            .text("Bluetooth", icon: "wave.3.right", detail: "On", chevron: true) {},
            .toggle("Airplane Mode", icon: "airplane", isOn: $off),
            .toggle("Low Power Mode", icon: "battery.25percent", isOn: $off),
            .toggle("Dark Appearance", icon: "moon.fill", isOn: $on),
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
