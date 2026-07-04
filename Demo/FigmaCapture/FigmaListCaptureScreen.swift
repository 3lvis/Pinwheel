import SwiftUI
import Pinwheel

// Captures a list where each row is a grouped, editable component: structured `PinLabel`s plus the
// row's native bits (a Toggle / chevron, rasterized) nested under a per-row container. Rows lay out
// eagerly (finite data), so every row — below the fold included — resolves and captures; the
// container groups each row's children into one Figma frame. (Hand-wired; macros come later.)
struct FigmaListCaptureScreen: SwiftUI.View {
    @State private var toggles = Array(repeating: true, count: 18)

    var body: some SwiftUI.View {
        FigmaCaptureHost(name: "List", content: content) { document in
            FigmaCaptureFile.write(document)
        }
    }

    private var content: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<18, id: \.self) { index in
                    row(index)
                    Divider()
                }
            }
        }
        .background(.primaryBackground)
    }

    @ViewBuilder
    private func row(_ index: Int) -> some SwiftUI.View {
        HStack(spacing: .spacingS) {
            VStack(alignment: .leading, spacing: .spacingXXS) {
                PinLabel("Row \(index + 1)").font(.body)
                PinLabel("Supporting text").font(.caption).color(.secondary)
            }
            Spacer()
            if index.isMultiple(of: 2) {
                CapturedImageView("Toggle") {
                    Toggle("", isOn: $toggles[index]).labelsHidden()
                }
            } else {
                CapturedImageView("Chevron") {
                    Image(systemName: "chevron.right").foregroundStyle(.secondaryText)
                }
            }
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .pinCapturedContainer(name: "Row \(index + 1)", fillTokenName: PinColorToken.primaryBackground.rawValue)
    }
}
