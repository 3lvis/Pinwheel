import SwiftUI
import Pinwheel

// A deliberately busier layout than PinButtonDemo — side-by-side rows, a space-between row, a
// bordered card, and two differently-aligned columns — to harden the Figma capture against
// non-vertical-list arrangements.
struct PinButtonLayoutDemo: SwiftUI.View {
    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingL) {
                PinLabel("Checkout").font(.title)

                HStack(spacing: .spacingM) {
                    PinButton("Cancel") {}.style(.secondary)
                    PinButton("Pay") {}
                }

                HStack {
                    PinButton("Back", systemImage: "chevron.left") {}.style(.tertiary)
                    Spacer()
                    PinButton("Skip") {}.style(.tertiary)
                    PinButton("Next", systemImage: "arrow.right") {}
                }

                VStack(alignment: .leading, spacing: .spacingM) {
                    PinLabel("Payment method").font(.subtitleSemibold)
                    HStack(spacing: .spacingS) {
                        PinButton("Card") {}.style(.secondary)
                        PinButton("Cash") {}.style(.secondary)
                        PinButton("Points") {}.style(.secondary)
                    }
                }
                .padding(.spacingL)
                .background(.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: .spacingM))
                // A decorative card isn't a Pin* component, so opt it into capture explicitly —
                // its fill/radius and column layout become an editable Figma frame around the buttons.
                .pinCapturedContainer(
                    name: "PaymentCard",
                    fillTokenName: PinColorToken.secondaryBackground.rawValue,
                    cornerRadius: .spacingM,
                    layout: PinCaptureLayout(
                        axis: .column, spacing: .spacingM,
                        padding: EdgeInsets(top: .spacingL, leading: .spacingL, bottom: .spacingL, trailing: .spacingL),
                        alignment: .leading
                    )
                )

                HStack(alignment: .top, spacing: .spacingL) {
                    VStack(alignment: .leading, spacing: .spacingS) {
                        PinLabel("Draft").font(.caption).color(.secondary)
                        PinButton("Alpha") {}.style(.secondary)
                        PinButton("Beta") {}.style(.tertiary)
                    }
                    VStack(alignment: .trailing, spacing: .spacingS) {
                        PinLabel("Status").font(.caption).color(.secondary)
                        PinButton("Saving", systemImage: "arrow.right") {}.loading()
                        PinButton("Done") {}
                    }
                }

                PinButton("Place order", systemImage: "checkmark") {}
                    .frame(maxWidth: .infinity)
            }
            .padding(.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.primaryBackground)
    }
}
