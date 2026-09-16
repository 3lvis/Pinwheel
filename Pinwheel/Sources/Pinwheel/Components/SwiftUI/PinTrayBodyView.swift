import SwiftUI
import UIKit

@MainActor
final class PinTrayBodyView: UIView {
    private let scroll = UIScrollView()
    private let hosting: UIHostingController<AnyView>

    private weak var coordinating: PinTrayBodyCoordinating?

    var clearance: CGFloat = 0 {
        didSet { scroll.contentInset.bottom = clearance }
    }

    init(
        showing content: AnyView,
        in parent: UIViewController,
        reporting to: PinTrayBodyCoordinating
    ) {
        coordinating = to
        hosting = UIHostingController(rootView: content)
        super.init(frame: .zero)

        scroll.backgroundColor = .clear
        scroll.alwaysBounceVertical = true
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.keyboardDismissMode = .interactive
        scroll.contentInset.top = traySectionGap
        scroll.showsVerticalScrollIndicator = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        hosting.view.backgroundColor = .clear
        hosting.safeAreaRegions = []
        hosting.sizingOptions = .intrinsicContentSize
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        parent.addChild(hosting)
        scroll.addSubview(hosting.view)
        hosting.didMove(toParent: parent)

        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
        ])

        scroll.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("PinTrayBodyView is made in code") }

    override func layoutSubviews() {
        super.layoutSubviews()
        scroll.isScrollEnabled = overflows
    }

    // The tray's parts each take their content through `show`, and each writes a stored property of
    // its own. Written at the call site the chassis would reach two levels down, past the part into
    // what it hosts.
    // oida:disable:next no_single_use_void_functions
    func show(_ content: AnyView) {
        hosting.rootView = content
    }

    func contentHeight(fitting width: CGFloat) -> CGFloat {
        hosting.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
            + scroll.contentInset.top
            + scroll.contentInset.bottom
    }

    var scrollableHeight: CGFloat { scroll.contentSize.height }

    var overflows: Bool {
        bounds.width > 0 && contentHeight(fitting: bounds.width) > bounds.height
    }

    var scrolls: Bool { scroll.isScrollEnabled }

    var fade: CGFloat {
        get { alpha }
        set { alpha = newValue }
    }

    func detach() {
        hosting.willMove(toParent: nil)
        hosting.view.removeFromSuperview()
        hosting.removeFromParent()
    }
}

extension PinTrayBodyView {
    static func cardTakes(_ past: CGFloat, alreadyPulling: Bool) -> Bool {
        past > 0 || alreadyPulling
    }
}

extension PinTrayBodyView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let past = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        let alreadyPulling = coordinating?.cardIsBeingDraggedDown ?? false
        guard scrollView.isTracking, Self.cardTakes(past, alreadyPulling: alreadyPulling) else { return }
        scrollView.contentOffset.y = -scrollView.contentInset.top
        coordinating?.bodyDragged(by: past)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        coordinating?.bodyWillBeginDragging()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard coordinating?.cardIsBeingDraggedDown == true else { return }
        coordinating?.bodyEndedDragging(withVelocity: -velocity.y * 1_000)
    }
}
