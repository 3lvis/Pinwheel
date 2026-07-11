import SwiftUI
import Pinwheel

struct CartDemo: SwiftUI.View {
    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let now: String
        let was: String?
        let quantity: Int
        var onSale: Bool { was != nil }
    }

    private let items = [
        Item(title: "Wireless Earbuds Pro", now: "$129", was: "$159", quantity: 1),
        Item(title: "LED Desk Lamp", now: "$34", was: "$49", quantity: 1),
        Item(title: "Cotton Crew T-Shirt", now: "$24", was: nil, quantity: 2),
        Item(title: "Insulated Water Bottle", now: "$21", was: "$28", quantity: 1)
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingM) {
                ForEach(items) { item in
                    HStack(spacing: .spacingM) {
                        RoundedRectangle(cornerRadius: .radiusM)
                            .fill(.secondaryBackground)
                            .frame(width: 56, height: 56)
                            .overlay(Image(systemName: "photo").foregroundStyle(.tertiaryText))
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            HStack(spacing: .spacingS) {
                                PinLabel(item.title).font(.body)
                                if item.onSale {
                                    PinLabel("SALE").font(.footnote).color(.custom(.white))
                                        .padding(.horizontal, .spacingS)
                                        .padding(.vertical, 2)
                                        .background(.criticalBackground, in: Capsule())
                                }
                            }
                            HStack(spacing: .spacingS) {
                                PinLabel(item.now).font(.bodySemibold)
                                if let was = item.was {
                                    PinLabel(was).font(.caption).color(.secondary).strikethrough()
                                }
                            }
                        }
                        Spacer()
                        PinLabel("−    \(item.quantity)    +").font(.body).color(.action)
                            .padding(.horizontal, .spacingM)
                            .padding(.vertical, .spacingS)
                            .overlay(Capsule().stroke(.tertiaryText, lineWidth: 1))
                    }
                    .padding(.spacingM)
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
