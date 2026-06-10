import UIKit
import Pinwheel

/// Demos the `PinwheelItem(_:id:viewController:)` seam by hosting a
/// `UIKitPinStateView` inside a raw `UIViewController`. Carries the same state
/// tweaks and retry reaction as `UIKitPinStateViewExample` (which is `view:`-
/// hosted), so the view-controller path is exercised under the same interactions
/// — switch to Failed, tap the retry button, and the delegate flips it to loading.
class UIKitPinViewControllerExample: UIViewController, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.stateView.state = .loading(title: DemoStateFixture.loadingTitle, subtitle: DemoStateFixture.loadingSubtitle)
            },
            TextTweak(title: "Loaded") {
                self.stateView.state = .loaded
            },
            TextTweak(title: "Empty") {
                self.stateView.state = .empty(title: DemoStateFixture.emptyTitle, subtitle: DemoStateFixture.emptySubtitle)
            },
            TextTweak(title: "Failed") {
                self.stateView.state = .failed(title: DemoStateFixture.failedTitle, subtitle: DemoStateFixture.failedSubtitle, actionTitle: DemoStateFixture.retryActionTitle)
            }
        ]
    }()

    lazy var stateView: UIKitPinStateView = {
        let view = UIKitPinStateView()
        view.delegate = self
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryBackground
        view.addSubview(stateView)
        stateView.fillInSuperview()
    }
}

extension UIKitPinViewControllerExample: UIKitPinStateViewDelegate {
    func stateViewDidSelectAction(_ stateView: UIKitPinStateView) {
        stateView.state = .loading(title: DemoStateFixture.loadingTitle, subtitle: DemoStateFixture.loadingSubtitle)
    }
}
