import SwiftUI
import UIKit

@MainActor
final class PinTrayBodyView: UIView {
    private let scroll = UIScrollView()
    private let hosting: UIHostingController<AnyView>
    private let edge: PinTrayLeafView
    private let bottomEdge: PinTrayLeafView
    private let bottomEdgeHeightConstraint: NSLayoutConstraint

    private weak var coordinating: PinTrayBodyCoordinating?

    var clearance: CGFloat = 0 {
        didSet {
            scroll.contentInset.bottom = clearance
            bottomEdgeHeightConstraint.constant = Self.bottomEdgeHeight(clearance: clearance)
        }
    }

    init(
        showing content: AnyView,
        in parent: UIViewController,
        reporting to: PinTrayBodyCoordinating
    ) {
        coordinating = to
        hosting = UIHostingController(rootView: content)
        edge = PinTrayLeafView(
            showing: AnyView(
                LinearGradient(
                    colors: [.primaryBackground, .primaryBackground.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            ),
            in: parent
        )
        bottomEdge = PinTrayLeafView(
            showing: AnyView(
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.primaryBackground.opacity(0), .primaryBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Self.edgeHeight)
                    Color.primaryBackground
                }
            ),
            in: parent
        )
        bottomEdgeHeightConstraint = bottomEdge.heightAnchor.constraint(equalToConstant: Self.bottomEdgeHeight(clearance: 0))
        super.init(frame: .zero)

        scroll.backgroundColor = .clear
        scroll.alwaysBounceVertical = true
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.keyboardDismissMode = .interactive
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

        edge.alpha = 0
        edge.isUserInteractionEnabled = false
        edge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(edge)

        bottomEdge.alpha = 0
        bottomEdge.isUserInteractionEnabled = false
        bottomEdge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomEdge)

        NSLayoutConstraint.activate([
            edge.leadingAnchor.constraint(equalTo: leadingAnchor),
            edge.trailingAnchor.constraint(equalTo: trailingAnchor),
            edge.topAnchor.constraint(equalTo: topAnchor),
            edge.heightAnchor.constraint(equalToConstant: Self.edgeHeight),
            bottomEdge.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomEdge.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomEdge.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomEdgeHeightConstraint,
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
        showEdges()
    }

    private func showEdges() {
        edge.alpha = Self.edgeOpacity(scrolled: scroll.contentOffset.y + scroll.contentInset.top)
        let below = scroll.contentSize.height + scroll.contentInset.bottom - scroll.bounds.height - scroll.contentOffset.y
        bottomEdge.alpha = Self.edgeOpacity(scrolled: below)
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

    // How the body reports a pull, and the point testABodyReportsEachSliceOfAPullAndKeepsNoRunningTotal
    // drives: each frame's own slice, never a running total, which is the bug that made a 400-point drag
    // move the card nine points.
    // oida:disable:next no_single_use_void_functions
    func wasPulled(pastTheTop past: CGFloat) {
        coordinating?.bodyDragged(by: past)
    }

    // Each tray part detaches itself and its own children, which is the vocabulary the chassis tears
    // the tray down through. Written at the call site a parent would reach past the part into what
    // it hosts.
    // oida:disable:next no_single_use_void_functions
    func detach() {
        hosting.detachFromParent()
        edge.detach()
        bottomEdge.detach()
    }
}

extension PinTrayBodyView {
    static let edgeHeight: CGFloat = 40

    static func edgeOpacity(scrolled distance: CGFloat) -> CGFloat {
        min(1, max(0, distance) / 24)
    }

    static func bottomEdgeHeight(clearance: CGFloat) -> CGFloat {
        edgeHeight + max(0, clearance - traySectionGap)
    }

    static func cardTakes(_ past: CGFloat, alreadyPulling: Bool) -> Bool {
        past > 0 || alreadyPulling
    }
}

extension PinTrayBodyView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        showEdges()
        let past = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        let alreadyPulling = coordinating?.cardIsBeingDraggedDown ?? false
        guard scrollView.isTracking, Self.cardTakes(past, alreadyPulling: alreadyPulling) else { return }
        scrollView.contentOffset.y = -scrollView.contentInset.top
        wasPulled(pastTheTop: past)
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
