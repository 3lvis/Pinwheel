import SwiftUI
import Pinwheel

struct LazyCardsDemo: SwiftUI.View {
    private let items = (1...20).map { "Item \($0)" }

    var body: some SwiftUI.View {
        ScrollView {
            LazyVStack(spacing: .spacingM) {
                ForEach(items, id: \.self) { title in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel(title).font(.caption).color(.secondary)
                        PinLabel("Detail row").font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacingL)
                    .background(.secondaryBackground)
                    .cornerRadius(.radiusM)
                }
            }
            .padding(.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.primaryBackground)
    }
}
