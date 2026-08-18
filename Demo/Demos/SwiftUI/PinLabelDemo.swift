import SwiftUI
import Pinwheel

struct PinLabelDemo: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacing4) {
            PinLabel("Title").font(.title)
            PinLabel("Subtitle").font(.subtitle)
            PinLabel("Body")
            PinLabel("Footnote").font(.footnote)
            PinLabel("Caption").font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.spacing4)
        .background(.primaryBackground)
    }
}
