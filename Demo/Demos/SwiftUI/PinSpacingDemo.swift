import SwiftUI
import Pinwheel

struct PinSpacingDemo: SwiftUI.View {
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

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: .spacingXXL) {
                ForEach(spacings, id: \.0) { title, spacing in
                    PinLabel("\(title) \(Int(spacing))")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingS)
                        .background(.tertiaryText)
                        .padding(.horizontal, spacing)
                }
            }
            .padding(.top, .spacingXXL)
        }
        .background(.primaryBackground)
    }
}
