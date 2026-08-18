import SwiftUI
import Pinwheel

struct PinTweakableDemo: SwiftUI.View {
    @SwiftUI.State private var alignmentIndex = 1
    @SwiftUI.State private var isUppercase = false

    private let text = "Tweak this label."
    private let alignmentTitles = ["Leading", "Center", "Trailing"]
    private let alignments: [Alignment] = [.leading, .center, .trailing]

    var body: some SwiftUI.View {
        PinLabel(isUppercase ? text.uppercased() : text)
            .padding(.spacing8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignments[alignmentIndex])
            .background(.primaryBackground)
            .pinwheelTweaks {
                PinwheelTweak("Alignment", options: alignmentTitles, selection: $alignmentIndex)
                PinwheelTweak("Uppercase", isOn: $isUppercase)
                PinwheelTweak("Reset") {
                    alignmentIndex = 1
                    isUppercase = false
                }
            }
    }
}
