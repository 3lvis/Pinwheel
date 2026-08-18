import UIKit
import Pinwheel

class UIPinViewControllerDemo: UIViewController, Tweakable {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .primaryBackground
        view.addSubview(stateView, filling: .all)
    }

    private func show(_ index: Int) {
        stateIndex = index
        stateView.state = DemoStateFixture.viewState(at: index)
    }
}

extension UIPinViewControllerDemo: UIPinStateViewDelegate {
    func stateViewDidSelectAction(_ stateView: UIPinStateView) {
        show(DemoStateFixture.loadingIndex)
    }
}
