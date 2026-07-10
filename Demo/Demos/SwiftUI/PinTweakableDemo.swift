import SwiftUI
import Pinwheel

struct PinTweakableDemo: SwiftUI.View {
    @SwiftUI.State private var selection = "Tap the button and choose an option."
    @SwiftUI.State private var isOn = false

    var body: some SwiftUI.View {
        PinLabel(selection)
            .multilineTextAlignment(.center)
            .padding(.spacingXXL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.primaryBackground)
            .pinwheelTweaks {
                PinwheelTweak("Option 1") {
                    selection = "You chose Option 1."
                }

                PinwheelTweak("Option 2", description: "Description 2") {
                    selection = "You chose Option 2."
                }

                PinwheelTweak("Option 3", description: "Toggle-backed option", isOn: $isOn)
            }
            .onChange(of: isOn) { _, value in
                selection = "Option 3 is \(value ? "on" : "off")."
            }
    }
}
