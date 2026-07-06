import SwiftUI
import Pinwheel

struct PinStateViewDemo: SwiftUI.View {
    @SwiftUI.State private var state: PinState = DemoStateFixture.empty

    var body: some SwiftUI.View {
        PinStateView(state) {
            state = DemoStateFixture.loading
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("Loading") { state = DemoStateFixture.loading }
            PinwheelTweak("Loaded") { state = .loaded }
            PinwheelTweak("Empty") { state = DemoStateFixture.empty }
            PinwheelTweak("Failed") { state = DemoStateFixture.failed }
        }
    }
}
