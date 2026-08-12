import SwiftUI
import Pinwheel

struct LazyGridDemo: SwiftUI.View {
    private let items = (1...12).map { "Tile \($0)" }
    private let columns = [GridItem(.flexible(), spacing: .spacingM), GridItem(.flexible(), spacing: .spacingM)]

    var body: some SwiftUI.View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: .spacingM) {
                ForEach(items, id: \.self) { title in
                    PinLabel(title)
                        .font(.body)
                        .frame(maxWidth: .infinity)
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
