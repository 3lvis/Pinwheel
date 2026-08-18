import SwiftUI

/// SwiftUI rather than UIKit: measured, a `UIVisualEffectView` carrying a `UIGlassEffect` gets the
/// press flex but never the bridge that merges neighbouring glass, so its capsules never join.
struct PinwheelFloatingButtons: SwiftUI.View {
    let theme: PinwheelTheme
    let tweakCount: Int
    let onTweaks: () -> Void
    let onClose: () -> Void

    var body: some SwiftUI.View {
        content
            .overlay(alignment: .topTrailing) { badge }
            .environment(\.pinwheelTheme, theme)
    }

    @ViewBuilder
    private var content: some SwiftUI.View {
        if #available(iOS 26, *) {
            GlassEffectContainer { stack }
        } else {
            stack
        }
    }

    private var stack: some SwiftUI.View {
        VStack(spacing: .spacing3) {
            button("slider.horizontal.3", label: "Tweaks", action: onTweaks)
                .accessibilityIdentifier("pinwheel.settings")
            button("xmark", label: "Close", action: onClose)
                .accessibilityIdentifier("pinwheel.close")
        }
    }

    @ViewBuilder
    private func button(_ symbol: String, label: String, action: @escaping () -> Void) -> some SwiftUI.View {
        let content = SwiftUI.Button(action: action) {
            Image(systemName: symbol)
                .font(PinTextStyle.body.font(in: theme))
                .symbolRenderingMode(.monochrome)
                .imageScale(.large)
                .frame(width: .minimumControlHeight, height: .minimumControlHeight)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.actionText)
        .accessibilityLabel(label)

        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(Circle().fill(Color.secondaryBackground))
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private var badge: some SwiftUI.View {
        if tweakCount > 0 {
            Text("\(tweakCount)")
                .font(PinTextStyle.caption.font(in: theme))
                .foregroundStyle(Color.primaryBackground)
                .frame(width: .spacing5, height: .spacing5)
                .background(Circle().fill(Color.actionText))
                .offset(x: .spacing1, y: -.spacing1)
        }
    }
}
