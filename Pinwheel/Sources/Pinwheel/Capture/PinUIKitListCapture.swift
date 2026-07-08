import UIKit

// Captures a UIKit table/collection by force-realizing every cell and reading the real UIView tree.
//
// A recycled UICollectionView/UITableView realizes only its visible viewport, so the SwiftUI
// DisplayList path (and even a layer crop) sees nothing off-screen. But a scroll view's cell-culling
// window IS its bounds: size the view to its full contentSize and every cell dequeues at once. Demo
// data is small, so recycling is moot — we read the whole thing. UILabels expose text/font/color
// directly, so a cell's content transposes to editable Figma nodes without any capture cooperation.
@MainActor
public enum PinUIKitListCapture {
    public static func document(host: UIView, name: String, size: CGSize, screenHeight: CGFloat) -> FigmaDocument? {
        host.layoutIfNeeded()
        guard let scroll = firstCellContainer(in: host) else { return nil }
        let rows = withAllCellsRealized(scroll) { realizedRows(scroll, in: host) }
        guard !rows.isEmpty else { return nil }

        let contentBottom = rows.map { $0.y + $0.h }.max() ?? Double(size.height)
        let background = (scroll.backgroundColor).flatMap { $0.cgColor.alpha > 0 ? $0 : nil }
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: Double(size.width), h: max(Double(screenHeight), contentBottom),
            fill: background.map(RGBA.init), fillToken: background.flatMap(PinDisplayListCapture.tokenName(for:)),
            name: name, children: rows
        )
        return FigmaDocument(width: Double(size.width), height: root.h, root: root,
                             tokens: PinDisplayListCapture.colorTokens + PinFloatTokens.tokens, textStyles: [])
    }

    private static func firstCellContainer(in view: UIView) -> UIScrollView? {
        if let table = view as? UITableView { return table }
        if let collection = view as? UICollectionView { return collection }
        for subview in view.subviews {
            if let found = firstCellContainer(in: subview) { return found }
        }
        return nil
    }

    private static func cells(of scroll: UIScrollView) -> [UIView] {
        if let table = scroll as? UITableView { return table.visibleCells }
        if let collection = scroll as? UICollectionView { return collection.visibleCells }
        return []
    }

    // A scroll view culls cells whose frame leaves its bounds, so expanding bounds to the full
    // contentSize realizes every cell. Restore afterward so the on-screen host is untouched.
    private static func withAllCellsRealized<T>(_ scroll: UIScrollView, _ body: () -> T) -> T {
        let savedFrame = scroll.frame
        let savedOffset = scroll.contentOffset
        scroll.frame = CGRect(x: savedFrame.minX, y: savedFrame.minY,
                              width: savedFrame.width, height: max(scroll.contentSize.height, savedFrame.height))
        scroll.contentOffset = .zero
        scroll.layoutIfNeeded()
        defer {
            scroll.frame = savedFrame
            scroll.contentOffset = savedOffset
            scroll.layoutIfNeeded()
        }
        return body()
    }

    private static func realizedRows(_ scroll: UIScrollView, in host: UIView) -> [FigmaNode] {
        cells(of: scroll)
            .sorted { $0.frame.minY < $1.frame.minY }
            .compactMap { rowNode($0, in: host) }
    }

    private static func rowNode(_ cell: UIView, in host: UIView) -> FigmaNode? {
        let frame = cell.convert(cell.bounds, to: host)
        guard frame.height > 1 else { return nil }
        let content = (cell as? UITableViewCell)?.contentView ?? cell
        let children = contentNodes(in: content, host: host)
        guard !children.isEmpty else { return nil }
        return FigmaNode(
            tag: "frame", x: Double(frame.minX), y: Double(frame.minY),
            w: Double(frame.width), h: Double(frame.height), name: "Row", children: children
        )
    }

    private static func contentNodes(in view: UIView, host: UIView) -> [FigmaNode] {
        var nodes: [FigmaNode] = []
        func walk(_ current: UIView) {
            for subview in current.subviews where !subview.isHidden && subview.alpha > 0.01 {
                if let label = subview as? UILabel, let node = textNode(label, host: host) {
                    nodes.append(node)
                } else if let node = controlNode(subview, host: host) {
                    nodes.append(node)
                } else {
                    walk(subview)
                }
            }
        }
        walk(view)
        return nodes.sorted { $0.x < $1.x }
    }

    private static func textNode(_ label: UILabel, host: UIView) -> FigmaNode? {
        guard let text = label.text, !text.isEmpty else { return nil }
        let frame = label.convert(label.bounds, to: host)
        // A UILabel in a fill-aligned stack gets a frame far wider than its text; capturing that width
        // makes Figma justify a short string across the whole box ("s u b t i t l e"). Read the tight
        // text rect and keep the natural (leading) origin so the box hugs the glyphs.
        let fit = label.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude))
        let width = min(ceil(fit.width), frame.width)
        let height = min(ceil(fit.height), frame.height)
        let box = CGRect(x: frame.minX, y: frame.minY, width: width, height: height)
        return FigmaNode(
            tag: "text", x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height),
            font: PinDisplayListCapture.figmaFont(label.font, color: label.textColor, underline: false),
            texts: [FigmaText(text: text, x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height))],
            children: []
        )
    }

    // A switch/image/control bakes its appearance into pixels, so crop the live render (front buffer,
    // no screen-update commit — the same discipline the SwiftUI control crop uses).
    private static func controlNode(_ view: UIView, host: UIView) -> FigmaNode? {
        guard view is UISwitch || view is UIImageView, view.bounds.width > 1, view.bounds.height > 1 else { return nil }
        if let imageView = view as? UIImageView, imageView.image == nil { return nil }
        let frame = view.convert(view.bounds, to: host)
        let image = autoreleasepool { () -> String? in
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            let rendered = renderer.image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: false) }
            return rendered.pngData()?.base64EncodedString()
        }
        guard let image else { return nil }
        return FigmaNode(
            tag: "image", x: Double(frame.minX), y: Double(frame.minY),
            w: Double(frame.width), h: Double(frame.height), image: image, children: []
        )
    }
}
