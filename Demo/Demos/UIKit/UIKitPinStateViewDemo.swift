import UIKit
import Pinwheel

class UIKitPinStateViewDemo: UIKitPinView, Tweakable {
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
        view.state = .empty(title: DemoStateFixture.emptyTitle, subtitle: DemoStateFixture.emptySubtitle)
        return view
    }()

    override func setup() {
        addSubview(stateView)
        stateView.fillInSuperview()
    }
}

extension UIKitPinStateViewDemo: UIKitPinStateViewDelegate {
    func stateViewDidSelectAction(_ stateView: Pinwheel.UIKitPinStateView) {
        stateView.state = .loading(title: DemoStateFixture.loadingTitle, subtitle: DemoStateFixture.loadingSubtitle)
    }
}
