import SwiftUI
import Pinwheel

struct PinTableViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Account", subtitle: "Signed in", chevron: true) {}.leading(Image(systemName: "person.crop.circle.fill")),
            .text("Notifications", chevron: true) {}.leading(Image(systemName: "bell.badge.fill")),
            .text("Privacy & Security", chevron: true) {}.leading(Image(systemName: "lock.fill")),
            .text("General", chevron: true) {}.leading(Image(systemName: "gearshape.fill")),
            .text("Wi-Fi", detail: "Home", chevron: true) {}.leading(Image(systemName: "wifi")),
            .text("Bluetooth", detail: "On", chevron: true) {}.leading(Image(systemName: "wave.3.right")),
            .toggle("Airplane Mode", isOn: $off).leading(Image(systemName: "airplane")),
            .toggle("Low Power Mode", isOn: $off).leading(Image(systemName: "battery.25percent")),
            .toggle("Dark Appearance", isOn: $on).leading(Image(systemName: "moon.fill")),
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
