import SwiftUI
import UIKit

/// Coordinates the floating tweak/close controls — the UIKit `CornerAnchoringView`
/// hosted in a pass-through overlay window — with the SwiftUI catalog/preview.
///
/// The controls live in a separate `UIWindow` so they float *above* sheet
/// presentations and never clip to (or clash with) the presented content. The
/// SwiftUI side only reads/writes this coordinator; the window observes it.
@MainActor
@Observable
final class PinwheelChrome {
    /// The presented component's tweaks. Held here (a persistent reference) rather
    /// than in the playground's `@State` so they survive playground re-renders /
    /// identity changes — the deep-link preview otherwise lost them when the
    /// settings sheet opened, leaving the sheet empty.
    var tweaks: [PinwheelTweak] = []
    /// Whether a component is currently presented — gates the FAB's visibility.
    var isPresentingItem: Bool = false
    /// Drives the SwiftUI settings sheet; the wrench button sets this `true`.
    var showsSettings: Bool = false
    /// Dismisses the presented component; the close button invokes this.
    var onClose: (() -> Void)?

    /// Badge count shown on the tweak (wrench) button.
    var tweakCount: Int { tweaks.count }

    /// The FAB shows only while a component is presented and the settings sheet
    /// is closed (so it never floats over the settings sheet itself).
    var isFloatingControlsVisible: Bool {
        isPresentingItem && !showsSettings
    }

    func selectSettings() { showsSettings = true }
    func selectClose() { onClose?() }
}

/// Installs a pass-through overlay `UIWindow` hosting the UIKit
/// `CornerAnchoringView` FAB and pushes `PinwheelChrome` state into it. Placed as
/// a background of the catalog/preview root; touches outside the FAB buttons fall
/// through to the app below.
struct PinwheelFloatingControlsHost: UIViewRepresentable {
    let chrome: PinwheelChrome
    let tweakCount: Int
    let isVisible: Bool

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
            context.coordinator.update(tweakCount: chrome.tweakCount, isVisible: chrome.isFloatingControlsVisible)
        }
        return probe
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        if let scene = uiView.window?.windowScene {
            context.coordinator.attach(scene: scene, chrome: chrome)
        }
        context.coordinator.update(tweakCount: tweakCount, isVisible: isVisible)
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
        private var visible = false

        func attach(scene: UIWindowScene, chrome: PinwheelChrome) {
            guard window == nil else { return }
            let window = PinwheelFloatingControlsWindow(windowScene: scene)
            window.controller.onSettings = { [weak chrome] in chrome?.selectSettings() }
            window.controller.onClose = { [weak chrome] in chrome?.selectClose() }
            self.window = window
        }

        func update(tweakCount: Int, isVisible: Bool) {
            guard let window else { return }
            window.controller.itemsCount = tweakCount
            setVisible(isVisible, on: window)
        }

        /// Fade the FAB out as the settings sheet rises (and back in on dismiss /
        /// when an item is presented) rather than toggling `isHidden` abruptly.
        private func setVisible(_ shouldShow: Bool, on window: PinwheelFloatingControlsWindow) {
            guard shouldShow != visible else { return }
            visible = shouldShow

            if shouldShow {
                window.alpha = 0
                window.isHidden = false
                UIView.animate(withDuration: 0.25) { window.alpha = 1 }
            } else {
                UIView.animate(withDuration: 0.25) {
                    window.alpha = 0
                } completion: { [weak self] _ in
                    // Skip hiding if we were asked to show again mid-animation.
                    if self?.visible == false { window.isHidden = true }
                }
            }
        }

        func teardown() {
            visible = false
            window?.isHidden = true
            window = nil
        }
    }
}

/// A pass-through window: only the FAB buttons capture touches; everything else
/// falls through to the app window below. The hosted `CornerAnchoringView`
/// already reports `point(inside:)` only over its buttons, and
/// `PinwheelPassthroughView` forwards that up to the window's root.
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
        guard let hit = super.hitTest(point, with: event) else { return nil }
        // Only actual FAB buttons (descendants of the anchoring view) capture
        // touches; everywhere else the window is transparent so the app below
        // stays interactive. `UIWindow.hitTest` returns the window itself for
        // empty areas, which would otherwise swallow every touch.
        return hit.isDescendant(of: controller.anchoringView) ? hit : nil
    }
}

/// Hosts the UIKit `CornerAnchoringView` in the overlay window and forwards its
/// button taps to the coordinator.
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
