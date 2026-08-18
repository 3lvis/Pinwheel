import SwiftUI
import Pinwheel

struct PricingDemo: SwiftUI.View {
    private struct Deal: Identifiable {
        let id = UUID()
        let title: String
        let now: String
        let was: String
    }

    private let deals = [
        Deal(title: "Wireless Earbuds Pro", now: "$129", was: "$159"),
        Deal(title: "LED Desk Lamp", now: "$34", was: "$49"),
        Deal(title: "Hardcover Notebook Set", now: "$18", was: "$25"),
        Deal(title: "Insulated Water Bottle", now: "$21", was: "$28")
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacing3) {
                ForEach(deals) { deal in
                    VStack(alignment: .leading, spacing: .spacing1) {
                        PinLabel(deal.title).font(.body)
                        HStack(spacing: .spacing2) {
                            PinLabel(deal.now).font(.bodySemibold)
                            PinLabel(deal.was).font(.caption).color(.secondary).strikethrough()
                        }
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
