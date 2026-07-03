import SwiftUI
import Pinwheel

// A screen built from Pinwheel components, each tagged for capture. Hosting it
// under -FigmaCapture writes Documents/figma-capture.json for the fonno plugin.
struct FigmaCaptureScreen: SwiftUI.View {
    var body: some SwiftUI.View {
        FigmaCaptureHost(content: sample) { document in
            FigmaCaptureFile.write(document)
        }
    }

    private var sample: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingM) {
            PinLabel("Checkout")
                .font(.title)
                .figmaCapture(component: "Label", text: "Checkout", textColor: .primary, fontSize: 28, fontWeight: 700)

            PinLabel("2 items in your basket")
                .font(.body)
                .color(.secondary)
                .figmaCapture(component: "Label", text: "2 items in your basket", textColor: .secondary, fontSize: 17)

            Spacer()

            PinButton("Pay now") {}
                .style(.primary)
                .figmaCapture(component: "Button", fill: .actionText, radius: 24, text: "Pay now", textColor: .primary, fontSize: 17, fontWeight: 600)

            PinButton("Cancel") {}
                .style(.secondary)
                .figmaCapture(component: "Button", fill: .secondaryBackground, radius: 24, text: "Cancel", fontSize: 17, fontWeight: 600)
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.primaryBackground)
    }
}
