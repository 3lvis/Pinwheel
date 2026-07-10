import SwiftUI
import Pinwheel

struct ProductListDemo: SwiftUI.View {
    private struct Product: Identifiable {
        let id = UUID()
        let title: String
        let now: String
        let was: String?
        let quantity: Int
        var onSale: Bool { was != nil }
    }

    @SwiftUI.State private var recommended: [Product] = [
        Product(title: "Wireless Earbuds Pro", now: "$129", was: "$159", quantity: 1),
        Product(title: "Cotton Crew T-Shirt", now: "$24", was: nil, quantity: 2),
        Product(title: "Ceramic Coffee Mug", now: "$12", was: nil, quantity: 1)
    ]
    @SwiftUI.State private var deals: [Product] = [
        Product(title: "LED Desk Lamp", now: "$34", was: "$49", quantity: 1),
        Product(title: "Hardcover Notebook Set", now: "$18", was: "$25", quantity: 3),
        Product(title: "Insulated Water Bottle", now: "$21", was: "$28", quantity: 1)
    ]

    var body: some SwiftUI.View {
        List {
            Section("Recommended") {
                ForEach(recommended) { row($0) }
            }
            Section("On sale") {
                ForEach(deals) { row($0) }
                    .onDelete { deals.remove(atOffsets: $0) }
            }
        }
        .listStyle(.plain)
    }

    private func row(_ product: Product) -> some SwiftUI.View {
        HStack(spacing: .spacingM) {
            RoundedRectangle(cornerRadius: .radiusM)
                .fill(.secondaryBackground)
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "photo").foregroundStyle(.tertiaryText))
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingS) {
                    PinLabel(product.title).font(.body)
                    if product.onSale {
                        PinLabel("SALE").font(.footnote).color(.custom(.white))
                            .padding(.horizontal, .spacingS)
                            .padding(.vertical, 2)
                            .background(.criticalBackground, in: Capsule())
                    }
                }
                HStack(spacing: .spacingS) {
                    PinLabel(product.now).font(.bodySemibold)
                    if let was = product.was {
                        PinLabel(was).font(.caption).color(.secondary).strikethrough()
                    }
                }
            }
            Spacer()
            HStack(spacing: .spacingM) {
                Image(systemName: "minus")
                PinLabel("\(product.quantity)").font(.body)
                Image(systemName: "plus")
            }
            .foregroundStyle(.actionText)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .overlay(Capsule().stroke(.tertiaryText, lineWidth: 1))
        }
        .padding(.vertical, .spacingXS)
    }
}
