import SwiftUI
import Pinwheel

struct LazyGridDemo: SwiftUI.View {
    private let items = (1...12).map { "Tile \($0)" }
    private let columns = [GridItem(.flexible(), spacing: .spacing3), GridItem(.flexible(), spacing: .spacing3)]

    var body: some SwiftUI.View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: .spacing3) {
                ForEach(items, id: \.self) { title in
                    PinLabel(title)
                        .font(.body)
                        .frame(maxWidth: .infinity)
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
