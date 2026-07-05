import SwiftUI
import Pinwheel

struct PinColorExample: SwiftUI.View {
    private let colors: [(String, UIColor)] = [
        ("Primary Text", .primaryText),
        ("Secondary Text", .secondaryText),
        ("Tertiary Text", .tertiaryText),
        ("Action Text", .actionText),
        ("Critical Text", .criticalText),
        ("Primary Background", .primaryBackground),
        ("Secondary Background", .secondaryBackground),
        ("Action Background", .actionBackground),
        ("Critical Background", .criticalBackground)
    ]

    var body: some SwiftUI.View {
        List(colors, id: \.0) { title, color in
            HStack {
                PinLabel(title).color(.custom(.black))
                PinLabel(title).color(.custom(.white))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(SwiftUI.Color(uiColor: color))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.primaryBackground)
    }
}
