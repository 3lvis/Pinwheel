import SwiftUI
import Pinwheel

struct PinLabelDemo: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingL) {
            PinLabel("Title").font(.title)
            PinLabel("Subtitle").font(.subtitle)
            PinLabel("Body")
            PinLabel("Footnote").font(.footnote)
            PinLabel("Caption").font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacingL)
        .background(.primaryBackground)
    }
}
