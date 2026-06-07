import SwiftUI
import UIKit

public struct PinwheelUIKitView<ViewType: UIView>: UIViewRepresentable {
    private let makeView: () -> ViewType

    public init(view: ViewType.Type) {
        self.makeView = { ViewType(frame: .zero) }
    }

    public init(makeView: @escaping () -> ViewType) {
        self.makeView = makeView
    }

    public func makeUIView(context: Context) -> ViewType {
        return makeView()
    }

    public func updateUIView(_ uiView: ViewType, context: Context) {
    }
}

public struct PinwheelUIKitViewController: UIViewControllerRepresentable {
    private let makeViewController: () -> UIViewController

    public init(makeViewController: @escaping () -> UIViewController) {
        self.makeViewController = makeViewController
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        return makeViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
