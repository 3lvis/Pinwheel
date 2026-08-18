import SwiftUI

/// A run of items that belong together. Carries no title.
public struct PinTraySection<Content: SwiftUI.View>: SwiftUI.View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some SwiftUI.View {
        VStack(spacing: trayItemGap) { content() }
    }
}
