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

    // No capture tagging — PinLabel/PinButton emit their own style via `.pinCaptured`.
    private var sample: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingM) {
            PinLabel("Checkout")
                .font(.title)

            PinLabel("2 items in your basket")
                .font(.body)
                .color(.secondary)

            Spacer()

            PinButton("Pay now") {}
                .style(.primary)

            PinButton("Cancel") {}
                .style(.secondary)
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.primaryBackground)
    }
}
