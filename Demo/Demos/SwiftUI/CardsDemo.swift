import SwiftUI
import Pinwheel

struct CardsDemo: SwiftUI.View {
    private let metrics = [("Revenue", "$12,480"), ("Orders", "1,204"), ("Users", "8,910"), ("Refunds", "37")]
    private let statuses = [("Sync", "Up to date"), ("Backup", "Complete"), ("Storage", "72% used"), ("Plan", "Pro")]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingM) {
                ForEach(metrics, id: \.0) { title, value in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel(title).font(.caption).color(.secondary)
                        PinLabel(value).font(.title)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacingL)
                    .background(.secondaryBackground)
                    .cornerRadius(.radiusM)
                }
                ForEach(statuses, id: \.0) { title, value in
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        PinLabel(title).font(.caption).color(.secondary)
                        PinLabel(value).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.spacingM)
                    .background(.actionBackground)
                    .cornerRadius(.radiusL)
                }
            }
            .padding(.spacingL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.primaryBackground)
    }
}
