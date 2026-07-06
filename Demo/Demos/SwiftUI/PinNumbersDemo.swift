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
        ("radiusM", .radiusM)
    ]

    // Set the outer radius; each inset derives its own inner radius from the gap.
    private let concentricOuter: CGFloat = 24
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
            }
            .padding(.spacingL)
            .padding(.top, .spacingXXL)
        }
        .background(.primaryBackground)
    }

    // An inner box inset from a rounded outer box keeps its corners parallel — the
    // two share a corner center — when its radius is the outer radius minus the
    // inset, clamped at 0 once the inset swallows the radius.
    private func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }

    @ViewBuilder
    private func concentricExample(inset: CGFloat) -> some SwiftUI.View {
        let inner = concentricRadius(outer: concentricOuter, inset: inset)
        VStack(alignment: .leading, spacing: .spacingS) {
            PinLabel("outer \(Int(concentricOuter)) · inset \(Int(inset)) → inner \(Int(inner))")
                .font(.caption).color(.secondary)
            if #available(iOS 26, *) {
                ZStack {
                    ConcentricRectangle().fill(.tertiaryText)
                    ConcentricRectangle().fill(.primaryBackground).padding(inset)
                }
                .frame(height: 96)
                .containerShape(.rect(cornerRadius: concentricOuter))
            } else {
                RoundedRectangle(cornerRadius: concentricOuter)
                    .fill(.tertiaryText)
                    .frame(height: 96)
                    .overlay {
                        RoundedRectangle(cornerRadius: inner)
                            .fill(.primaryBackground)
                            .padding(inset)
                    }
            }
        }
    }
}
