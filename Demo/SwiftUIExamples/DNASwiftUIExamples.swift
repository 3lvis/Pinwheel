import SwiftUI
import Pinwheel

struct PinFontExample: SwiftUI.View {
    // The themed typography surface (provider-backed), mirroring UIKitPinFontExample.
    private let fonts: [(String, Font)] = [
        ("Title", PinwheelTheme.Typography.title),
        ("Subtitle", PinwheelTheme.Typography.subtitle),
        ("Subtitle Semibold", PinwheelTheme.Typography.subtitleSemibold),
        ("Body", PinwheelTheme.Typography.body),
        ("Footnote", PinwheelTheme.Typography.footnote),
        ("Caption", PinwheelTheme.Typography.caption)
    ]

    var body: some SwiftUI.View {
        List(fonts, id: \.0) { title, font in
            Text(title)
                .font(font)
                .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                .listRowBackground(SwiftUI.Color(uiColor: .primaryBackground))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
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
                Text(title)
                    .foregroundStyle(.black)
                Text(title)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(SwiftUI.Color(uiColor: color))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(SwiftUI.Color(uiColor: .primaryBackground))
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
                    Text("\(title) \(Int(spacing))")
                        .font(.body)
                        .foregroundStyle(SwiftUI.Color(uiColor: .primaryText))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingS)
                        .background(SwiftUI.Color(uiColor: .tertiaryText))
                        .padding(.horizontal, spacing)
                }
            }
            .padding(.top, .spacingXXL)
        }
        .background(SwiftUI.Color(uiColor: .primaryBackground))
    }
}
