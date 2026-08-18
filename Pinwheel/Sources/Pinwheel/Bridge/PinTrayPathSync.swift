import SwiftUI
import UIKit

final class PinTrayPathSync<Item: Hashable> {
    private var overlay: PinTrayChassis?
    private var shown: [Item] = []

    var dismissAll: () -> Void = {}
    var exit: () -> Void = {}

    static func isPush(to arriving: Int, from standing: Int) -> Bool { arriving >= standing }

    static func exited(_ path: [Item]) -> [Item] { Array(path.dropLast()) }

    func sync(
        path: [Item],
        from presenter: UIViewController,
        tray: (Item) -> PinTray
    ) {
        guard path != shown else {
            if let top = path.last {
                overlay?.refresh(tray(top))
            }
            return
        }
        defer { shown = path }

        guard let top = path.last else {
            overlay?.dismiss()
            return
        }

        let description = tray(top)

        if let overlay {
            overlay.depth = path.count - 1
            overlay.show(description, isPush: Self.isPush(to: path.count, from: shown.count))
            return
        }

        guard var container = presenter.view.window?.rootViewController else { return }
        while let presented = container.presentedViewController { container = presented }

        let screen = container.view.window?.screen ?? UIScreen.main
        let created = PinTrayChassis(
            showing: description,
            nestedIn: screen.pinDisplayCornerRadius,
            covering: container.view.bounds
        )
        created.depth = path.count - 1
        created.onExit = { [weak self] in self?.exit() }
        created.onGone = { [weak self] in
            self?.overlay = nil
            self?.dismissAll()
        }

        container.addChild(created)
        container.view.addSubview(created.view, filling: .all)
        created.didMove(toParent: container)
        overlay = created
    }
}
