import SwiftUI
import UIKit

struct PinwheelFloatingControlsHost: UIViewRepresentable {
    let chrome: PinwheelChrome
    let tweakCount: Int
    let showsFloatingControls: Bool
    // The floating controls live in their own window, which neither `.preferredColorScheme` nor the bridged theme trait reaches.
    var colorScheme: ColorScheme?
    var theme: PinwheelTheme

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
                showsFloatingControls: chrome.isFloatingControlsVisible,
                tweakCount: chrome.tweakCount,
                colorScheme: chrome.colorScheme,
                theme: chrome.theme
            )
        }
        return probe
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        if let scene = uiView.window?.windowScene {
            context.coordinator.attach(scene: scene, chrome: chrome)
        }
        context.coordinator.update(
            showsFloatingControls: showsFloatingControls,
            tweakCount: tweakCount,
            colorScheme: colorScheme,
            theme: theme
        )
    }

    static func dismantleUIView(_ uiView: ProbeView, coordinator: Coordinator) {
        coordinator.teardown()
    }

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
        private var floatingControlsAreShown = false

        func attach(scene: UIWindowScene, chrome: PinwheelChrome) {
            guard window == nil else { return }
            let window = PinwheelFloatingControlsWindow(windowScene: scene)
            window.controller.onSettings = { [weak chrome] in chrome?.showsTweaks = true }
            window.controller.onClose = { [weak chrome] in chrome?.selectClose() }
            window.controller.anchoringView.setControlsHidden(true, animated: false)
            self.window = window
        }

        func update(
            showsFloatingControls: Bool,
            tweakCount: Int,
            colorScheme: ColorScheme?,
            theme: PinwheelTheme
        ) {
            guard let window else { return }
            window.controller.itemsCount = tweakCount
            window.controller.theme = theme
            window.traitOverrides[PinwheelThemeTrait.self] = theme
            switch colorScheme {
            case .light: window.overrideUserInterfaceStyle = .light
            case .dark: window.overrideUserInterfaceStyle = .dark
            default: window.overrideUserInterfaceStyle = .unspecified
            }

            if showsFloatingControls { window.isHidden = false }

            if showsFloatingControls != floatingControlsAreShown {
                floatingControlsAreShown = showsFloatingControls
                window.controller.anchoringView.setControlsHidden(!showsFloatingControls, animated: true) {
                    if !showsFloatingControls { window.isHidden = true }
                }
            } else if !showsFloatingControls {
                window.isHidden = true
            }
        }

        // The window and the flag it clears are this coordinator's own private state, so the call site
        // above has nothing it could write instead.
        // oida:disable:next no_single_use_void_functions
        func teardown() {
            floatingControlsAreShown = false
            window?.isHidden = true
            window = nil
        }
    }
}
