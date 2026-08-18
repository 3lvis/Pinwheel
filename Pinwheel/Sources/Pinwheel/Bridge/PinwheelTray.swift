import SwiftUI
import UIKit

extension SwiftUI.View {
    /// Presents a sequence of trays driven by `path`: appending pushes, removing pops, emptying
    /// dismisses. `content` is asked for the tray at the top of the path.
    public func pinwheelTray<Item: Hashable>(
        path: SwiftUI.Binding<[Item]>,
        content: @escaping (Item) -> PinTray
    ) -> some SwiftUI.View {
        background(PinTrayPresenter(path: path, content: content))
    }
}

private struct PinTrayPresenter<Item: Hashable>: UIViewControllerRepresentable {
    @SwiftUI.Binding var path: [Item]
    let content: (Item) -> PinTray

    func makeCoordinator() -> PinTrayPathSync<Item> {
        PinTrayPathSync()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.dismissAll = { path.removeAll() }
        coordinator.exit = { path = PinTrayPathSync<Item>.exited(path) }
        coordinator.sync(path: path, from: controller, tray: content)
    }
}
