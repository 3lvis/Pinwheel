import UIKit

public extension UIView {
    func addSubview(_ view: UIView, filling edges: NSDirectionalRectEdge, insets: UIEdgeInsets = .zero) {
        addSubview(view)
        view.pin(to: ownAnchors, edges: edges, insets: insets)
    }

    func addSubview(_ view: UIView, filling edges: NSDirectionalRectEdge, margin: CGFloat) {
        addSubview(view, filling: edges, insets: UIEdgeInsets(margin))
    }

    func addSubview(
        _ view: UIView,
        filling guide: UILayoutGuide,
        edges: NSDirectionalRectEdge = .all,
        insets: UIEdgeInsets = .zero
    ) {
        addSubview(view)
        view.pin(
            to: (guide.topAnchor, guide.leadingAnchor, guide.trailingAnchor, guide.bottomAnchor),
            edges: edges,
            insets: insets
        )
    }

    func addSubview(
        _ view: UIView,
        filling guide: UILayoutGuide,
        edges: NSDirectionalRectEdge = .all,
        margin: CGFloat
    ) {
        addSubview(view, filling: guide, edges: edges, insets: UIEdgeInsets(margin))
    }

    func addSubview(
        _ view: UIView,
        top: NSLayoutYAxisAnchor,
        leading: NSLayoutXAxisAnchor,
        trailing: NSLayoutXAxisAnchor,
        bottom: NSLayoutYAxisAnchor,
        insets: UIEdgeInsets = .zero
    ) {
        addSubview(view)
        view.pin(to: (top, leading, trailing, bottom), edges: .all, insets: insets)
    }

    func insertSubview(
        _ view: UIView,
        belowSubview sibling: UIView,
        filling edges: NSDirectionalRectEdge,
        insets: UIEdgeInsets = .zero
    ) {
        insertSubview(view, belowSubview: sibling)
        view.pin(to: ownAnchors, edges: edges, insets: insets)
    }
}

private typealias PinnedEdges = (
    top: NSLayoutYAxisAnchor,
    leading: NSLayoutXAxisAnchor,
    trailing: NSLayoutXAxisAnchor,
    bottom: NSLayoutYAxisAnchor
)

private extension UIView {
    var ownAnchors: PinnedEdges {
        (topAnchor, leadingAnchor, trailingAnchor, bottomAnchor)
    }

    func pin(to target: PinnedEdges, edges: NSDirectionalRectEdge, insets: UIEdgeInsets) {
        var constraints: [NSLayoutConstraint] = []
        if edges.contains(.top) {
            constraints.append(topAnchor.constraint(equalTo: target.top, constant: insets.top))
        }
        if edges.contains(.leading) {
            constraints.append(leadingAnchor.constraint(equalTo: target.leading, constant: insets.leading))
        }
        if edges.contains(.trailing) {
            constraints.append(trailingAnchor.constraint(equalTo: target.trailing, constant: -insets.trailing))
        }
        if edges.contains(.bottom) {
            constraints.append(bottomAnchor.constraint(equalTo: target.bottom, constant: -insets.bottom))
        }
        NSLayoutConstraint.activate(constraints)
    }
}

private extension UIEdgeInsets {
    init(_ margin: CGFloat) {
        self.init(top: margin, leading: margin, bottom: margin, trailing: margin)
    }
}

extension NSLayoutConstraint {
    public func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
