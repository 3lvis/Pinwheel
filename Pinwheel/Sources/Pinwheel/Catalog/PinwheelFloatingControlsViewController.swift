import SwiftUI
import UIKit

final class PinwheelFloatingControlsViewController: UIViewController, CornerAnchoringViewDelegate {
    let anchoringView = CornerAnchoringView()
    var onSettings: (() -> Void)?
    var onClose: (() -> Void)?

    var theme: PinwheelTheme = .standard {
        didSet { refreshButtons() }
    }

    var itemsCount: Int {
        get { anchoringView.itemsCount }
        set { anchoringView.itemsCount = newValue }
    }

    private lazy var buttonsController = UIHostingController(rootView: buttons)

    private var buttons: PinwheelFloatingButtons {
        PinwheelFloatingButtons(
            theme: theme,
            tweakCount: anchoringView.itemsCount,
            onTweaks: { [weak self] in self?.onSettings?() },
            onClose: { [weak self] in self?.onClose?() }
        )
    }

    private func refreshButtons() {
        buttonsController.rootView = buttons
    }

    override func loadView() {
        let container = PinwheelPassthroughView()
        anchoringView.delegate = self
        anchoringView.onItemsCountChange = { [weak self] _ in self?.refreshButtons() }
        container.addSubview(anchoringView)
        NSLayoutConstraint.activate([
            anchoringView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            anchoringView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            anchoringView.topAnchor.constraint(equalTo: container.topAnchor),
            anchoringView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container

        buttonsController.view.backgroundColor = .clear
        addChild(buttonsController)
        anchoringView.setButtonsContent(buttonsController.view)
        buttonsController.didMove(toParent: self)
    }

    func cornerAnchoringViewDidSelectTweakButton(_ cornerAnchoringView: CornerAnchoringView) {
        onSettings?()
    }

    func cornerAnchoringViewDidSelectCloseButton(_ cornerAnchoringView: CornerAnchoringView) {
        onClose?()
    }
}
