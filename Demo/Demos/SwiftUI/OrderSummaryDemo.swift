import SwiftUI
import Pinwheel

struct OrderSummaryDemo: SwiftUI.View {
    private struct Item: Identifiable {
        let id = UUID()
        let title: String
        let detail: String?
        let label: String?
        let bonus: String?
        let discount: String?
        let quantity: String
        let tax: String
        let price: String
    }

    private let items = [
        Item(title: "Organic Bananas", detail: "≈ 1.2 kg", label: nil, bonus: "Bonus", discount: nil,
             quantity: "2 × kr 24,90", tax: "15% VAT", price: "kr 49,80"),
        Item(title: "Whole Milk 1L", detail: "6-pack", label: "Replaced", bonus: nil, discount: nil,
             quantity: "1 × kr 119,00", tax: "15% VAT", price: "kr 119,00"),
        Item(title: "Sourdough Loaf", detail: nil, label: nil, bonus: nil, discount: "−20%",
             quantity: "1 × kr 39,00", tax: "15% VAT", price: "kr 31,20"),
        Item(title: "Free-Range Eggs", detail: "12-pack", label: nil, bonus: nil, discount: nil,
             quantity: "1 × kr 54,90", tax: "15% VAT", price: "kr 54,90"),
        Item(title: "Cold-Pressed Olive Oil", detail: "500 ml", label: "Not delivered", bonus: nil, discount: nil,
             quantity: "1 × kr 149,00", tax: "15% VAT", price: "kr 149,00"),
        Item(title: "Dark Roast Coffee", detail: "1 kg", label: nil, bonus: "Bonus", discount: "−15%",
             quantity: "2 × kr 189,00", tax: "15% VAT", price: "kr 321,30")
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingM) {
                ForEach(items) { item in
                    HStack(spacing: .spacingM) {
                        RoundedRectangle(cornerRadius: .radiusM)
                            .fill(.primaryBackground)
                            .frame(width: 64, height: 64)
                            .overlay(Image(systemName: "bag").foregroundStyle(.tertiaryText))
                        VStack(alignment: .leading, spacing: .spacingS) {
                            PinLabel(item.title).font(.bodySemibold)
                            if let detail = item.detail {
                                PinLabel(detail).font(.caption).color(.secondary)
                            }
                            HStack(spacing: .spacingS) {
                                if let label = item.label { pill(label, fill: .primaryBackground, text: .secondary) }
                                if let bonus = item.bonus { pill(bonus, fill: .actionBackground, text: .custom(.white)) }
                                if let discount = item.discount { pill(discount, fill: .criticalBackground, text: .custom(.white)) }
                                Spacer()
                                PinLabel(item.tax).font(.caption).color(.tertiary)
                            }
                            HStack(alignment: .bottom, spacing: .spacingM) {
                                PinLabel(item.quantity).font(.caption).color(.secondary)
                                Spacer()
                                PinLabel(item.price).font(.bodySemibold)
                            }
                        }
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

    private func pill(_ text: String, fill: Color, text textColor: PinLabel.TextColor) -> some SwiftUI.View {
        PinLabel(text).font(.footnote).color(textColor)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, 2)
            .background(fill, in: Capsule())
    }
}
