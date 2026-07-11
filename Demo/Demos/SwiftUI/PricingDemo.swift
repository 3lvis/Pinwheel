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
            VStack(spacing: .spacingM) {
                ForEach(deals) { deal in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel(deal.title).font(.body)
                        HStack(spacing: .spacingS) {
                            PinLabel(deal.now).font(.bodySemibold)
                            PinLabel(deal.was).font(.caption).color(.secondary).strikethrough()
                        }
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
