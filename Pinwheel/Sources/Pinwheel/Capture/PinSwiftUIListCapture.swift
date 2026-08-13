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

        // Section headers are supplementary views, not cells; capture both so a sectioned List keeps its
        // headers. Order by on-screen Y so headers land above their rows.
        let items = (orderedCells(collection) + sectionHeaders(collection))
            .sorted { $0.convert(CGPoint.zero, to: liveHost).y < $1.convert(CGPoint.zero, to: liveHost).y }
        let rows: [FigmaNode] = items.compactMap { structuredRow($0, in: liveHost) }
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
        // Repeated rows share one component (edit the master, the copies follow), same as the DisplayList path.
        let componentized = PinDisplayListCapture.componentizeRepeatedChildren(PinDisplayListCapture.stripDuplicateNestedBackground(root))
        return FigmaDocument(width: width, height: componentized.h, root: componentized,
                             tokens: PinDisplayListCapture.colorTokens + PinFloatTokens.tokens,
                             textStyles: PinDisplayListCapture.textStyles)
    }

    // The surface a
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

    private static func sectionHeaders(_ scroll: UIScrollView) -> [UIView] {
        guard let collection = scroll as? UICollectionView else { return [] }
        let kind = UICollectionView.elementKindSectionHeader
        return collection.indexPathsForVisibleSupplementaryElements(ofKind: kind)
            .compactMap { collection.supplementaryView(forElementKind: kind, at: $0) }
    }

    private static func orderedCells(_ scroll: UIScrollView) -> [UIView] {
        let cells: [UIView] = (scroll as? UICollectionView)?.visibleCells
            ?? (scroll as? UITableView)?.visibleCells
            ?? []
        return cells.sorted { $0.frame.minY < $1.frame.minY }
    }

    // Reassemble one cell into a structured row. A cell's whole row lives in its CellHostingView
    // DisplayList (thumbnail, title, pill, prices, stepper); gather the leaves of every hosting view in the
    // cell — shifted into cell coordinates — and build one node by containment, so nothing scatters.
    private static func structuredRow(_ cell: UIView, in liveHost: UIView) -> FigmaNode? {
        var leaves: [DisplayLeaf] = []
        for hosting in hostingViews(in: cell) {
            guard let hostingLeaves = PinDisplayList.leaves(fromHost: hosting, liveControlsOnScreen: true) else { continue }
            let offset = hosting.convert(CGPoint.zero, to: cell)
            leaves += hostingLeaves.map { leaf in
                var moved = DisplayLeaf(frame: leaf.frame.offsetBy(dx: offset.x, dy: offset.y), kind: leaf.kind)
                moved.image = leaf.image
                return moved
            }
        }
        guard let content = PinDisplayListCapture.containmentNode(leaves: leaves, host: cell) else { return nil }
        let origin = cell.convert(CGPoint.zero, to: liveHost)
        var node = shift(content, dx: Double(origin.x), dy: Double(origin.y))
        node.tag = "frame"
        node.name = "Row"
        return node
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

    private static func shift(_ node: FigmaNode, dx: Double, dy: Double) -> FigmaNode {
        var moved = node
        moved.x += dx
        moved.y += dy
        moved.texts = node.texts?.map { FigmaText(text: $0.text, x: $0.x + dx, y: $0.y + dy, w: $0.w, h: $0.h) }
        moved.children = node.children.map { shift($0, dx: dx, dy: dy) }
        return moved
    }
}
