import SwiftUI
import Pinwheel

struct PinListDemo: SwiftUI.View {
    private let products: [(String, String)] = [
        ("Wireless Earbuds Pro", "$129"),
        ("Cotton Crew T-Shirt", "$24"),
        ("Ceramic Coffee Mug", "$12"),
        ("LED Desk Lamp", "$34"),
        ("Hardcover Notebook Set", "$18"),
        ("Insulated Water Bottle", "$21")
    ]

    var body: some SwiftUI.View {
        PinList(rows: products.map { title, price in
            .text(title, detail: price, chevron: true)
        })
    }
}
