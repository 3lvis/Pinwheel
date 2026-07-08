import SwiftUI
import Pinwheel

struct PinTableViewDemo: SwiftUI.View {
    @SwiftUI.State private var state: PinState = .loaded
    @SwiftUI.State private var off = false
    @SwiftUI.State private var on = true

    var body: some SwiftUI.View {
        PinList(state: state, rows: [
            .text("Account", icon: Image(systemName: "person.crop.circle.fill"), subtitle: "Signed in", chevron: true) {},
            .text("Notifications", icon: Image(systemName: "bell.badge.fill"), chevron: true) {},
            .text("Privacy & Security", icon: Image(systemName: "lock.fill"), chevron: true) {},
            .text("General", icon: Image(systemName: "gearshape.fill"), chevron: true) {},
            .text("Wi-Fi", icon: Image(systemName: "wifi"), detail: "Home", chevron: true) {},
            .text("Bluetooth", icon: Image(systemName: "wave.3.right"), detail: "On", chevron: true) {},
            .toggle("Airplane Mode", icon: Image(systemName: "airplane"), isOn: $off),
            .toggle("Low Power Mode", icon: Image(systemName: "battery.25percent"), isOn: $off),
            .toggle("Dark Appearance", icon: Image(systemName: "moon.fill"), isOn: $on),
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
