import SwiftUI
import Pinwheel

// A screen built from Pinwheel components, each tagged for capture. Hosting it
// under -FigmaCapture writes Documents/figma-capture.json for the fonno plugin.
struct FigmaCaptureScreen: SwiftUI.View {
    @State private var deliveryMode = 0
    @State private var notify = true

    var body: some SwiftUI.View {
        FigmaCaptureHost(name: "Checkout", content: sample) { document in
            FigmaCaptureFile.write(document)
        }
    }

    // PinLabel/PinButton emit their own style via `@Pinnable`. The native segmented control and
    // the SF Symbol have no structured descriptor, so `CapturedImageView` rasterizes them.
    private var sample: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingM) {
                PinLabel("Checkout")
                    .font(.title)

                PinLabel("Review your order")
                    .font(.body)
                    .color(.secondary)

                CapturedImageView("DeliveryMode") {
                    Picker("", selection: $deliveryMode) {
                        Text("Delivery").tag(0)
                        Text("Pickup").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                CapturedImageView("CartIcon") {
                    Image(systemName: "cart.fill")
                        .font(.title)
                        .foregroundStyle(.actionText)
                }

                CapturedImageView("NotifySwitch") {
                    Toggle("", isOn: $notify).labelsHidden()
                }

                ForEach(1...24, id: \.self) { line in
                    PinLabel("Order line \(line)")
                        .font(.body)
                        .color(.secondary)
                }

                PinButton("Pay now") {}
                    .style(.primary)

                PinButton("Cancel") {}
                    .style(.secondary)
            }
            .padding(.spacingL)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(.primaryBackground)
    }
}
