import SwiftUI
import UIKit

// The theme environment value is trait-bridged, and a sheet or cover takes its traits from the
// window rather than from the SwiftUI view that presented it — so writing the override on the
// window is what reaches every presentation. A UIAlertController and the rest of the chrome the
// system presents for us take their colour from the window's tint instead of from any trait.
struct PinwheelThemedWindow: UIViewRepresentable {
    let theme: PinwheelTheme

    func makeUIView(context: Context) -> ProbeView {
        ProbeView(theme: theme)
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.theme = theme
    }

    final class ProbeView: UIView {
        var theme: PinwheelTheme {
            didSet { dressWindow() }
        }

        init(theme: PinwheelTheme) {
            self.theme = theme
            super.init(frame: .zero)
            isHidden = true
            isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("PinwheelThemedWindow.ProbeView is never loaded from an archive.")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            dressWindow()
        }

        private func dressWindow() {
            guard let window else { return }
            window.traitOverrides[PinwheelThemeTrait.self] = theme
            window.tintColor = theme.colors.actionText
        }
    }
}
