import SwiftUI
import Pinwheel

struct FigmaAutoLayoutScreen: SwiftUI.View {
    var body: some SwiftUI.View {
        FigmaCaptureHost(name: "AutoLayout", content: content) { document in
            FigmaCaptureFile.write(document)
        }
    }

    private var content: some SwiftUI.View {
        VStack(alignment: .leading, spacing: .spacingM) {
            PinLabel("Auto-layout").font(.title)
            PinLabel("This frame reflows when you edit it in Figma.").font(.body).color(.secondary)
            PinLabel("Lengthen a label or add a row — the stack adjusts.").font(.footnote).color(.secondary)
            PinButton("Got it") {}.style(.primary)
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinCapturedContainer(
            name: "Card",
            layout: PinCaptureLayout(
                axis: .column, spacing: .spacingM,
                padding: EdgeInsets(top: .spacingL, leading: .spacingL, bottom: .spacingL, trailing: .spacingL),
                alignment: .leading
            )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.primaryBackground)
    }
}
