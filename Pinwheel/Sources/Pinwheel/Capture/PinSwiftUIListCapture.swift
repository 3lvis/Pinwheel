import SwiftUI
import UIKit

// A SwiftUI `List` is a recycled `UICollectionView` whose every row is its own SwiftUI hosting boundary
// (`CellHostingView`), so the root host's DisplayList never sees the rows. Force every cell to realize
// (size the collection to its `contentSize`), then capture each cell's own hosting view — its DisplayList
// is reachable once `_base` is fetched via the ObjC runtime (Mirror hides it on `CellHostingView`) — and
// compose the rows into a screen. Returns nil when the host has no backing collection, so the caller falls
// through to the normal DisplayList path for non-`List` SwiftUI screens.
@MainActor
public enum PinSwiftUIListCapture {
    public static func document(name: String, size: CGSize, screenHeight: CGFloat, liveHost: UIView) -> FigmaDocument? {
        guard let collection = firstCollection(in: liveHost) else { return nil }
        realizeAllCells(collection)

        let rows: [FigmaNode] = orderedCells(collection).compactMap { cell in
            // A row's content is split across nested hosting views, each its own DisplayList boundary.
            // Capture every one and place it by its frame. Text-dominant rows capture fully; a rich row
            // with embedded controls captures partially — some fragments host their content in a way that
            // exposes no readable DisplayList (a known limitation, see the plan).
            let fragments: [FigmaNode] = hostingViews(in: cell).compactMap { hosting in
                guard let fragment = PinDisplayListCapture.document(
                    SwiftUI.EmptyView(), name: "Row", size: hosting.bounds.size,
                    screenHeight: hosting.bounds.height, liveHost: hosting
                ) else { return nil }
                guard !nodeTexts(fragment.root).isEmpty || !fragment.root.children.isEmpty else { return nil }
                let origin = hosting.convert(CGPoint.zero, to: liveHost)
                var node = shift(fragment.root, dx: Double(origin.x), dy: Double(origin.y))
                if node.tag == "screen" { node.tag = "frame" }
                return node
            }
            guard !fragments.isEmpty else { return nil }
            let frame = cell.convert(cell.bounds, to: liveHost)
            return FigmaNode(tag: "frame", x: Double(frame.minX), y: Double(frame.minY),
                             w: Double(frame.width), h: Double(frame.height), name: "Row", children: fragments)
        }
        guard !rows.isEmpty else { return nil }

        let top = rows.map { $0.y }.min() ?? 0
        let lifted = rows.map { shift($0, dx: 0, dy: -top) }
        let width = Double(size.width)
        let contentBottom = lifted.map { $0.y + $0.h }.max() ?? Double(screenHeight)
        // A `.plain` List's collection is transparent, so its screen would capture with no background; fall
        // back to the opaque surface actually rendered behind it (walking up to the window). Light and dark
        // sweep rounds each read their own surface, so the merge gives the screen an adapting background.
        let background = collection.backgroundColor.flatMap { $0.cgColor.alpha > 0 ? $0 : nil }
            ?? opaqueBackground(above: collection)
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: width, h: max(Double(screenHeight), contentBottom),
            fill: background.map(RGBA.init), fillToken: background.flatMap(PinDisplayListCapture.tokenName(for:)),
            name: name, children: lifted
        )
        return FigmaDocument(width: width, height: root.h, root: root,
                             tokens: PinDisplayListCapture.colorTokens + PinFloatTokens.tokens,
                             textStyles: PinDisplayListCapture.textStyles)
    }

    // The first opaque backgroundColor up the superview chain (including the window) — the surface a
    // transparent collection is drawn on.
    static func opaqueBackground(above view: UIView) -> UIColor? {
        var current: UIView? = view.superview
        while let candidate = current {
            if let color = candidate.backgroundColor, color.cgColor.alpha > 0 { return color }
            current = candidate.superview
        }
        return nil
    }

    private static func firstCollection(in view: UIView) -> UIScrollView? {
        if view is UICollectionView || view is UITableView { return view as? UIScrollView }
        for sub in view.subviews { if let found = firstCollection(in: sub) { return found } }
        return nil
    }

    private static func realizeAllCells(_ scroll: UIScrollView) {
        scroll.layoutIfNeeded()
        let full = scroll.contentSize.height
        guard full > scroll.bounds.height else { return }
        scroll.bounds = CGRect(x: scroll.bounds.minX, y: 0, width: scroll.bounds.width, height: full)
        scroll.frame.size.height = full
        scroll.layoutIfNeeded()
    }

    private static func orderedCells(_ scroll: UIScrollView) -> [UIView] {
        let cells: [UIView] = (scroll as? UICollectionView)?.visibleCells
            ?? (scroll as? UITableView)?.visibleCells
            ?? []
        return cells.sorted { $0.frame.minY < $1.frame.minY }
    }

    // Every hosting view in the cell, at any depth — each row fragment (title, price, stepper, image) is
    // its own DisplayList boundary, so all of them are needed to reassemble the row.
    private static func hostingViews(in view: UIView) -> [UIView] {
        var found: [UIView] = []
        func scan(_ view: UIView) {
            for sub in view.subviews {
                if String(describing: type(of: sub)).contains("HostingView") { found.append(sub) }
                scan(sub)
            }
        }
        scan(view)
        return found
    }

    private static func nodeTexts(_ node: FigmaNode) -> [String] {
        (node.texts?.map { $0.text } ?? []) + node.children.flatMap { nodeTexts($0) }
    }

    private static func shift(_ node: FigmaNode, dx: Double, dy: Double) -> FigmaNode {
        var moved = node
        moved.x += dx
        moved.y += dy
        moved.texts = node.texts?.map { FigmaText(text: $0.text, x: $0.x + dx, y: $0.y + dy, w: $0.w, h: $0.h) }
        moved.children = node.children.map { shift($0, dx: dx, dy: dy) }
        return moved
    }
}
