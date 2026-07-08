import SwiftUI
import Pinwheel

struct PinColorDemo: SwiftUI.View {
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

    // VStack, not List: a List's UIKit-backed cells don't render off-screen, so Figma capture reads them empty.
    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(colors, id: \.0) { title, color in
                    HStack {
                        PinLabel(title).color(.custom(.black))
                        PinLabel(title).color(.custom(.white))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingM)
                    .background(SwiftUI.Color(uiColor: color))
                }
            }
        }
        .background(.primaryBackground)
    }
}
