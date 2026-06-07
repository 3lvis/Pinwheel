import SwiftUI

struct PinSwiftUIFont: SwiftUI.View {
    private let fonts: [(String, Font)] = [
        ("Title", .title),
        ("Subtitle", .title3),
        ("Body", .body),
        ("Footnote", .footnote),
        ("Caption", .caption),
        ("Title Semibold", .title.weight(.semibold)),
        ("Subtitle Semibold", .title3.weight(.semibold)),
        ("Body Semibold", .body.weight(.semibold)),
        ("Footnote Semibold", .footnote.weight(.semibold)),
        ("Caption Semibold", .caption.weight(.semibold))
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

struct PinSwiftUIColor: SwiftUI.View {
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

struct PinSwiftUISpacing: SwiftUI.View {
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
