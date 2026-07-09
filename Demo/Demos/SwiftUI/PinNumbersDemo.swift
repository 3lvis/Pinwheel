import SwiftUI
import Pinwheel

struct PinNumbersDemo: SwiftUI.View {
    private let spacings: [(String, CGFloat)] = [
        ("spacingXXS", .spacingXXS),
        ("spacingXS", .spacingXS),
        ("spacingXM", .spacingXM),
        ("spacingS", .spacingS),
        ("spacingM", .spacingM),
        ("spacingL", .spacingL),
        ("spacingXL", .spacingXL),
        ("spacingXXL", .spacingXXL)
    ]

    private let radii: [(String, CGFloat)] = [
        ("radiusM", .radiusM),
        ("radiusL", .radiusL)
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingXXL) {
                PinLabel("Spacing").font(.title)
                ForEach(spacings, id: \.0) { title, spacing in
                    VStack(alignment: .leading, spacing: .spacingS) {
                        PinLabel("\(title) \(Int(spacing)) · radiusM \(Int(CGFloat.radiusM))").font(.caption).color(.secondary)
                        Color.clear
                            .frame(height: 44)
                            .background(.actionBackground, in: .rect(cornerRadius: .radiusM))
                            .padding(spacing)
                            .background(.tertiaryText, in: .rect(cornerRadius: .radiusM))
                    }
                }

                PinLabel("Radius").font(.title)
                ForEach(radii, id: \.0) { title, radius in
                    PinLabel("\(title) \(Int(radius))")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingL)
                        .background(.tertiaryText, in: RoundedRectangle(cornerRadius: radius))
                }
            }
            .padding(.spacingL)
            .padding(.top, .spacingXXL)
        }
        .background(.primaryBackground)
    }
}
