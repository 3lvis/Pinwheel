import SwiftUI

struct PinTrayTitleBar: SwiftUI.View {
    let title: String
    let isRoot: Bool
    let accessory: AnyView?
    let exit: () -> Void

    @Environment(\.pinwheelTheme) private var theme

    var body: some SwiftUI.View {
        ZStack {
            PinLabel(title)
                .font(.subtitleSemibold)
                .accessibilityIdentifier("pinwheel.tray.\(title).theme.\(theme.name)")
            HStack {
                SwiftUI.Button(action: exit) {
                    Image(systemName: isRoot ? "xmark" : "chevron.backward")
                        .font(PinTextStyle.body.font(in: theme))
                        .symbolRenderingMode(.monochrome)
                        .imageScale(.medium)
                }
                .tint(.primaryText)
                .accessibilityLabel(isRoot ? "Close" : "Back")
                Spacer()
                accessory
                    .font(PinTextStyle.body.font(in: theme))
                    .symbolRenderingMode(.monochrome)
                    .imageScale(.medium)
                    .tint(.primaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: .minimumControlHeight)
        .padding(.horizontal, trayContentMargin)
        .padding(.vertical, .spacing1)
    }
}
