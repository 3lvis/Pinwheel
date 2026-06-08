import UIKit
import Pinwheel

class PinStateView: UIKitPinView, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.stateView.state = .loading(title: "Loading...", subtitle: "Please wait while we fetch your details.")
            },
            TextTweak(title: "Loaded") {
                self.stateView.state = .loaded
            },
            TextTweak(title: "Empty") {
                self.stateView.state = .empty(title: "Ready to Move?", subtitle: "Kick things off with your first booking.")
            },
            TextTweak(title: "Failed") {
                self.stateView.state = .failed(title: "Oops!", subtitle: "We couldn't load your bookings.", actionTitle: "Retry")
            }
        ]
    }()

    lazy var stateView: UIKitPinStateView = {
        let view = UIKitPinStateView()
        view.delegate = self
        return view
    }()

    override func setup() {
        addSubview(stateView)
        stateView.fillInSuperview()
    }
}

extension PinStateView: UIKitPinStateViewDelegate {
    func stateViewDidSelectAction(_ stateView: Pinwheel.UIKitPinStateView) {
        print("action!")
    }
}
