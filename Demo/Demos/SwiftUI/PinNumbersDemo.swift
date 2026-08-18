import SwiftUI
import Pinwheel

struct PinNumbersDemo: SwiftUI.View {
    private let spacings: [(String, CGFloat)] = [
        ("spacing1", .spacing1),
        ("spacing2", .spacing2),
        ("spacing3", .spacing3),
        ("spacing4", .spacing4),
        ("spacing5", .spacing5),
        ("spacing6", .spacing6),
        ("spacing8", .spacing8)
    ]

    private let radii: [(String, CGFloat)] = [
        ("radiusM", .radiusM),
        ("radiusL", .radiusL)
    ]

    private let concentricOuter: CGFloat = .radiusL
    private let concentricInsets: [CGFloat] = [.spacing1, .spacing3, .spacing4]

    var body: some SwiftUI.View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing8) {
                PinLabel("Spacing").font(.title)
                ForEach(spacings, id: \.0) { title, spacing in
                    VStack(alignment: .leading, spacing: .spacing2) {
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
                        .padding(.vertical, .spacing4)
                        .background(.tertiaryText, in: RoundedRectangle(cornerRadius: radius))
                }

                PinLabel("Concentric radius").font(.title)
                ForEach(concentricInsets, id: \.self) { inset in
                    concentricExample(inset: inset)
                }
                concentricStack()
            }
            .padding(.spacing4)
            .padding(.top, .spacing8)
        }
        .background(.primaryBackground)
    }

    private func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }

    private func concentricExample(inset: CGFloat) -> some SwiftUI.View {
        let inner = concentricRadius(outer: concentricOuter, inset: inset)
        return VStack(alignment: .leading, spacing: .spacing2) {
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
        let gap: CGFloat = .spacing2
        let middle = concentricRadius(outer: concentricOuter, inset: gap)
        let inner = concentricRadius(outer: middle, inset: gap)
        return VStack(alignment: .leading, spacing: .spacing2) {
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
