import SwiftUI
import UIKit

// The theme environment value is trait-bridged, and a sheet or cover takes its traits from the
// window rather than from the SwiftUI view that presented it — so writing the override on the
// window is what reaches every presentation.
struct PinwheelThemedWindow: UIViewRepresentable {
    let theme: PinwheelTheme

    func makeUIView(context: Context) -> ProbeView {
        let probe = ProbeView()
        probe.isHidden = true
        probe.isUserInteractionEnabled = false
        let theme = theme
        probe.onMoveToWindow = { $0.traitOverrides[PinwheelThemeTrait.self] = theme }
        return probe
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.window?.traitOverrides[PinwheelThemeTrait.self] = theme
    }

    final class ProbeView: UIView {
        var onMoveToWindow: ((UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { onMoveToWindow?(window) }
        }
    }
}
