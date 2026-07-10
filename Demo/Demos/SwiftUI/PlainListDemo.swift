import SwiftUI
import Pinwheel

struct PlainListDemo: SwiftUI.View {
    private let items = (1...20).map { "Row \($0)" }

    var body: some SwiftUI.View {
        List {
            ForEach(items, id: \.self) { title in
                HStack {
                    PinLabel(title).font(.body)
                    Spacer()
                    PinLabel("Detail").font(.caption).color(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}
