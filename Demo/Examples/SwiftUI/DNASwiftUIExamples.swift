import SwiftUI
import Pinwheel

struct PinFontExample: SwiftUI.View {
    // The themed typography surface (provider-backed), mirroring UIKitPinFontExample.
    private let styles: [(String, PinTextStyle)] = [
        ("Title", .title),
        ("Subtitle", .subtitle),
        ("Subtitle Semibold", .subtitleSemibold),
        ("Body", .body),
        ("Footnote", .footnote),
        ("Caption", .caption)
    ]

    var body: some SwiftUI.View {
        List(styles, id: \.0) { title, style in
            PinLabel(title).font(style)
                .listRowBackground(PinwheelTheme.Colors.primaryBackground)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PinwheelTheme.Colors.primaryBackground)
    }
}

struct PinColorExample: SwiftUI.View {
    private let colors: [(String, UIColor)] = [
        ("Primary Text", .primaryText),
        ("Secondary Text", .secondaryText),
        ("Tertiary Text", .tertiaryText),
        ("Action Text", .actionText),
        ("Critical Text", .criticalText),
        ("Primary Background", .primaryBackground),
        ("Secondary Background", .secondaryBackground),
        ("Action Background", .actionBackground),
        ("Critical Background", .criticalBackground)
    ]

    var body: some SwiftUI.View {
        List(colors, id: \.0) { title, color in
            HStack {
                PinLabel(title).color(.custom(.black))
                PinLabel(title).color(.custom(.white))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(SwiftUI.Color(uiColor: color))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PinwheelTheme.Colors.primaryBackground)
    }
}

struct PinSpacingExample: SwiftUI.View {
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
                        .background(PinwheelTheme.Colors.tertiaryText)
                        .padding(.horizontal, spacing)
                }
            }
            .padding(.top, .spacingXXL)
        }
        .background(PinwheelTheme.Colors.primaryBackground)
    }
}
