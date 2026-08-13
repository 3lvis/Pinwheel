import SwiftUI
import Pinwheel

struct PinStateViewDemo: SwiftUI.View {
    @SwiftUI.State private var stateIndex = DemoStateFixture.emptyIndex

    var body: some SwiftUI.View {
        PinStateView(DemoStateFixture.state(at: stateIndex)) {
            stateIndex = DemoStateFixture.loadingIndex
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.primaryBackground)
        .pinwheelTweaks {
            PinwheelTweak("State", options: DemoStateFixture.titles, selection: $stateIndex)
        }
    }
}
