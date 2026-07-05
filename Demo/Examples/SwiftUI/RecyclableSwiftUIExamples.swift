import SwiftUI
import Pinwheel

struct PinTableViewExample: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Account", subtitle: "Signed in", chevron: true) {}.leading { icon("person.crop.circle.fill") },
            .text("Notifications", chevron: true) {}.leading { icon("bell.badge.fill") },
            .text("Privacy & Security", chevron: true) {}.leading { icon("lock.fill") },
            .text("General", chevron: true) {}.leading { icon("gearshape.fill") },
            .text("Wi-Fi", detail: "Home", chevron: true) {}.leading { icon("wifi") },
            .text("Bluetooth", detail: "On", chevron: true) {}.leading { icon("wave.3.right") },
            .toggle("Airplane Mode", isOn: $off).leading { icon("airplane") },
            .toggle("Low Power Mode", isOn: $off).leading { icon("battery.25percent") },
            .toggle("Dark Appearance", isOn: $on).leading { icon("moon.fill") },
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

    private func icon(_ name: String) -> some SwiftUI.View {
        Image(systemName: name).foregroundStyle(.actionText)
    }
}
