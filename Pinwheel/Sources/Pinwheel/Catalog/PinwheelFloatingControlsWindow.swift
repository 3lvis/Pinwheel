import SwiftUI
import UIKit

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
        // Over empty areas `UIWindow.hitTest` returns the window itself (or the
        // pass-through container); only deeper interactive views capture the touch.
        guard let hit = super.hitTest(point, with: event),
            hit !== self,
            hit !== controller.view
        else {
            return nil
        }
        return hit
    }
}
