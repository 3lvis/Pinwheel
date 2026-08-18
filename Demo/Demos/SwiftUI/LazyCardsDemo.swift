import SwiftUI
import Pinwheel

struct LazyCardsDemo: SwiftUI.View {
    private let items = (1...20).map { "Item \($0)" }

    var body: some SwiftUI.View {
        ScrollView {
            LazyVStack(spacing: .spacing3) {
                ForEach(items, id: \.self) { title in
                    VStack(alignment: .leading, spacing: .spacing1) {
                        PinLabel(title).font(.caption).color(.secondary)
                        PinLabel("Detail row").font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacing4)
                    .background(.secondaryBackground)
                    .cornerRadius(.radiusM)
                }
            }
            .padding(.spacing4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.primaryBackground)
    }
}
