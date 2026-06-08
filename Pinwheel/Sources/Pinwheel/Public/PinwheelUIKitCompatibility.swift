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

    // Fill the proposed size instead of collapsing to the view's fitting size.
    // Pinwheel's UIKit views (e.g. the DNA examples) pin their content to their
    // own edges and only look right at full size — as they would in a real
    // full-bounds UIKit hierarchy — so hugging here left them content-sized and
    // top-left in the catalog/preview.
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: ViewType, context: Context) -> CGSize? {
        return proposal.replacingUnspecifiedDimensions()
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
