import SwiftUI
import UIKit

/// Installs a pass-through overlay `UIWindow` hosting the UIKit `CornerAnchoringView`
/// FAB, and pushes `PinwheelChrome` state into it. Placed as a background of the
/// catalog/preview root; touches outside the FAB buttons fall through to the app
/// below. (The device pill rides on the playground itself, not this window.)
struct PinwheelFloatingControlsHost: UIViewRepresentable {
    let chrome: PinwheelChrome
    let tweakCount: Int
    let fabVisible: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ProbeView {
        let probe = ProbeView()
        probe.isHidden = true
        probe.isUserInteractionEnabled = false
        // Attach exactly when the probe enters a window — polling `updateUIView`
        // misses static hosts (e.g. the deep-link preview) that render once and
        // never re-run after the window becomes available.
        let chrome = chrome
        probe.onMoveToScene = { scene in
            context.coordinator.attach(scene: scene, chrome: chrome)
            context.coordinator.update(
                fabVisible: chrome.isFloatingControlsVisible,
                tweakCount: chrome.tweakCount
            )
        }
        return probe
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        if let scene = uiView.window?.windowScene {
            context.coordinator.attach(scene: scene, chrome: chrome)
        }
        context.coordinator.update(fabVisible: fabVisible, tweakCount: tweakCount)
    }

    static func dismantleUIView(_ uiView: ProbeView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    /// An invisible probe that reports when it enters a window scene, so the
    /// overlay window can be created at exactly the right moment.
    final class ProbeView: UIView {
        var onMoveToScene: ((UIWindowScene) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let scene = window?.windowScene {
                onMoveToScene?(scene)
            }
        }
    }

    @MainActor
    final class Coordinator {
        private var window: PinwheelFloatingControlsWindow?
        private var fabShown = false

        func attach(scene: UIWindowScene, chrome: PinwheelChrome) {
            guard window == nil else { return }
            let window = PinwheelFloatingControlsWindow(windowScene: scene)
            window.controller.onSettings = { [weak chrome] in chrome?.selectSettings() }
            window.controller.onClose = { [weak chrome] in chrome?.selectClose() }
            window.controller.anchoringView.setControlsHidden(true, animated: false)
            self.window = window
        }

        func update(fabVisible: Bool, tweakCount: Int) {
            guard let window else { return }
            window.controller.itemsCount = tweakCount

            if fabVisible { window.isHidden = false }

            // Animate the FAB (fade + shrink) only on a visibility change, then drop
            // the window once the FAB is gone (the pill lives on the playground, so
            // nothing else needs this window).
            if fabVisible != fabShown {
                fabShown = fabVisible
                window.controller.anchoringView.setControlsHidden(!fabVisible, animated: true) {
                    if !fabVisible { window.isHidden = true }
                }
            } else if !fabVisible {
                window.isHidden = true
            }
        }

        func teardown() {
            fabShown = false
            window?.isHidden = true
            window = nil
        }
    }
}

/// A pass-through window: only the FAB buttons capture touches; everything else
/// falls through to the app window below.
final class PinwheelFloatingControlsWindow: UIWindow {
    let controller = PinwheelFloatingControlsViewController()

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = .normal + 1
        backgroundColor = .clear
        rootViewController = controller
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Pass through everywhere except the FAB buttons. Over empty areas
        // `UIWindow.hitTest` returns the window itself (or the pass-through
        // container); only deeper interactive views should capture the touch.
        guard let hit = super.hitTest(point, with: event), hit !== self, hit !== controller.view else {
            return nil
        }
        return hit
    }
}

/// Hosts the UIKit `CornerAnchoringView` FAB and the SwiftUI device pill in the
/// overlay window, forwarding the FAB button taps to the coordinator.
final class PinwheelFloatingControlsViewController: UIViewController, CornerAnchoringViewDelegate {
    let anchoringView = CornerAnchoringView()
    var onSettings: (() -> Void)?
    var onClose: (() -> Void)?

    var itemsCount: Int {
        get { anchoringView.itemsCount }
        set { anchoringView.itemsCount = newValue }
    }

    override func loadView() {
        let container = PinwheelPassthroughView()
        anchoringView.delegate = self
        container.addSubview(anchoringView)
        NSLayoutConstraint.activate([
            anchoringView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            anchoringView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            anchoringView.topAnchor.constraint(equalTo: container.topAnchor),
            anchoringView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }

    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView) {
        onSettings?()
    }

    func cornerAnchoringViewDidSelectCloseButton(_ cornerAnchoringView: CornerAnchoringView) {
        onClose?()
    }
}

/// Forwards hit-testing to its subviews, so the surrounding overlay window is
/// transparent to touches everywhere except the FAB buttons.
final class PinwheelPassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews where !subview.isHidden && subview.isUserInteractionEnabled && subview.alpha > 0.01 {
            if subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
