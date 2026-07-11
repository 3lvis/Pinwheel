import SwiftUI
import Pinwheel

struct PinStepperDemo: SwiftUI.View {
    @SwiftUI.State private var quantity = 1
    @SwiftUI.State private var crate = 12

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingXL) {
                VStack(alignment: .leading, spacing: .spacingS) {
                    PinLabel("Quantity").font(.subtitleSemibold)
                    PinStepper(value: quantity)
                        .onDecrement { quantity = max(0, quantity - 1) }
                        .onIncrement { quantity += 1 }
                }

                VStack(alignment: .leading, spacing: .spacingS) {
                    PinLabel("Crate size").font(.subtitleSemibold)
                    PinStepper(value: crate)
                        .onDecrement { crate = max(0, crate - 1) }
                        .onIncrement { crate += 1 }
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingXXL)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.primaryBackground)
    }
}
