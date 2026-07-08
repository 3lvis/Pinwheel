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

    private let concentricOuter: CGFloat = .radiusL
    private let concentricInsets: [CGFloat] = [.spacingXS, .spacingM, .spacingL]

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

                PinLabel("Concentric radius").font(.title)
                ForEach(concentricInsets, id: \.self) { inset in
                    concentricExample(inset: inset)
                }
                concentricStack()
            }
            .padding(.spacingL)
            .padding(.top, .spacingXXL)
        }
        .background(.primaryBackground)
    }

    private func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }

    private func concentricExample(inset: CGFloat) -> some SwiftUI.View {
        let inner = concentricRadius(outer: concentricOuter, inset: inset)
        return VStack(alignment: .leading, spacing: .spacingS) {
            PinLabel("outer \(Int(concentricOuter)) · inset \(Int(inset)) → inner \(Int(inner))")
                .font(.caption).color(.secondary)
            Color.clear
                .frame(height: 96)
                .overlay {
                    Color.clear
                        .pinConcentricBackground(.primaryBackground, inset: inset)
                        .padding(inset)
                }
                .background(.tertiaryText, in: .rect(cornerRadius: concentricOuter))
                .pinConcentricContainer(cornerRadius: concentricOuter)
        }
    }

    private func concentricStack() -> some SwiftUI.View {
        let gap: CGFloat = .spacingS
        let middle = concentricRadius(outer: concentricOuter, inset: gap)
        let inner = concentricRadius(outer: middle, inset: gap)
        return VStack(alignment: .leading, spacing: .spacingS) {
            PinLabel("3 layers · gap \(Int(gap)) → \(Int(concentricOuter)) / \(Int(middle)) / \(Int(inner))")
                .font(.caption).color(.secondary)
            Color.clear
                .frame(height: 140)
                .overlay {
                    Color.clear
                        .pinConcentricBackground(.primaryBackground, inset: gap)
                        .overlay {
                            Color.clear
                                .pinConcentricBackground(.tertiaryText, inset: gap)
                                .padding(gap)
                                .pinConcentricContainer(cornerRadius: middle)
                        }
                        .padding(gap)
                }
                .background(.tertiaryText, in: .rect(cornerRadius: concentricOuter))
                .pinConcentricContainer(cornerRadius: concentricOuter)
        }
    }
}
