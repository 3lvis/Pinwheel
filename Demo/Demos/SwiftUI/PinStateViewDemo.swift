import SwiftUI
import Pinwheel

struct PinStateViewDemo: SwiftUI.View {
    @SwiftUI.State private var state: PinState = DemoStateFixture.empty

    @SwiftUI.State private var stateIndex = 2

    var body: some SwiftUI.View {
        PinStateView(state) {
            state = DemoStateFixture.loading
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("State", options: DemoStateFixture.titles, selection: $stateIndex)
        }
        .onChange(of: stateIndex) { _, index in state = DemoStateFixture.state(at: index) }
    }
}
