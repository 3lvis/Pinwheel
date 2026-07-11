import SwiftUI
import Pinwheel

// Built on PinList: each row is a 1-D value the capture reconstructs faithfully. A bespoke 2-D HStack row
// (thumbnail | title/price column | stepper) scrambles under the geometry-based capture path — PinList's
// value rows don't. Trade-off: the standalone SALE pill / ± stepper collapse into the row's text/detail.
struct CartDemo: SwiftUI.View {
    private struct Item {
        let title: String
        let now: String
        let was: String?
        let quantity: Int
    }

    private let items = [
        Item(title: "Wireless Earbuds Pro", now: "$129", was: "$159", quantity: 1),
        Item(title: "LED Desk Lamp", now: "$34", was: "$49", quantity: 1),
        Item(title: "Cotton Crew T-Shirt", now: "$24", was: nil, quantity: 2),
        Item(title: "Insulated Water Bottle", now: "$21", was: "$28", quantity: 1)
    ]

    var body: some SwiftUI.View {
        PinList(rows: items.map { item in
            .text(
                item.title,
                icon: Image(systemName: "bag"),
                subtitle: item.was.map { "\(item.now) · was \($0)" } ?? item.now,
                detail: "×\(item.quantity)"
            )
        })
    }
}
