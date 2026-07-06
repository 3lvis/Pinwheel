import SwiftUI
import Pinwheel

struct PinDimensionsDemo: SwiftUI.View {
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
        ("radiusM", .radiusM)
    ]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingXXL) {
                PinLabel("Spacing").font(.title)
                ForEach(spacings, id: \.0) { title, spacing in
                    PinLabel("\(title) \(Int(spacing))")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingS)
                        .background(.tertiaryText)
                        .padding(.horizontal, spacing)
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
