import UIKit
import Pinwheel

class UIPinStateViewDemo: UIPinView, Tweakable {
    private var stateIndex = DemoStateFixture.emptyIndex

    lazy var tweaks: [Tweak] = {
        return [
            SelectTweak(
                title: "State",
                options: DemoStateFixture.titles,
                chosenOption: { self.stateIndex },
                action: { self.show($0) }
            )
        ]
    }()

    lazy var stateView: UIPinStateView = {
        let view = UIPinStateView()
        view.delegate = self
        view.state = DemoStateFixture.viewState(at: stateIndex)
        return view
    }()

    override func setup() {
        addSubview(stateView, filling: .all)
    }

    private func show(_ index: Int) {
        stateIndex = index
        stateView.state = DemoStateFixture.viewState(at: index)
    }
}

extension UIPinStateViewDemo: UIPinStateViewDelegate {
    func stateViewDidSelectAction(_ stateView: Pinwheel.UIPinStateView) {
        show(DemoStateFixture.loadingIndex)
    }
}
