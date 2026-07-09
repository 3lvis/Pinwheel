import UIKit

// Captures a hosted UIKit component into the Figma IR by reading the real UIView tree — no DisplayList,
// no markers. A recycled UITableView/UICollectionView only realizes its visible viewport, so cells are
// force-realized first (a scroll view's cull window is its bounds; demo data is small, so sizing to the
// full contentSize realizes everything). UILabel/UISwitch/UIImageView map straight to Figma nodes.
@MainActor
public enum PinUIKitCapture {
    public static func document(host: UIView, name: String, size: CGSize, screenHeight: CGFloat) -> FigmaDocument? {
        host.layoutIfNeeded()
        let children: [FigmaNode]
        if let scroll = firstCellContainer(in: host) {
            let rows = withAllCellsRealized(scroll) { realizedRows(scroll, in: host) }
            guard !rows.isEmpty else { return nil }
            children = rows + separatorNodes(between: rows, table: scroll as? UITableView)
        } else {
            let walked = viewNodes(in: host, host: host)
            guard !walked.isEmpty else { return nil }
            children = walked
        }
        return assemble(children: children, background: hostedBackground(host), safeAreaTop: host.safeAreaInsets.top, name: name, size: size, screenHeight: screenHeight)
    }

    // Drop only the safe-area inset (the plugin's device frame draws the status bar), not the topmost
    // node's y — subtracting that would pin centered content (a lone centered label) to the top instead
    // of leaving it centered. Guard against overshoot for content that starts above the inset.
    private static func assemble(children: [FigmaNode], background: UIColor?, safeAreaTop: CGFloat, name: String, size: CGSize, screenHeight: CGFloat) -> FigmaDocument {
        let minY = children.map { $0.y }.min() ?? 0
        let lifted = children.map { shiftUp($0, by: min(Double(safeAreaTop), minY)) }
        let contentBottom = lifted.map { $0.y + $0.h }.max() ?? Double(size.height)
        let fill = background.flatMap { $0.cgColor.alpha > 0 ? $0 : nil }
        let root = FigmaNode(
            tag: "screen", x: 0, y: 0, w: Double(size.width), h: max(Double(screenHeight), contentBottom),
            fill: fill.map(RGBA.init), fillToken: fill.flatMap(PinDisplayListCapture.tokenName(for:)),
            name: name, children: lifted
        )
        return FigmaDocument(width: Double(size.width), height: root.h, root: root,
                             tokens: PinDisplayListCapture.colorTokens + PinFloatTokens.tokens, textStyles: PinDisplayListCapture.textStyles)
    }

    private static func shiftUp(_ node: FigmaNode, by offset: Double) -> FigmaNode {
        var lifted = node
        lifted.y -= offset
        lifted.texts = node.texts?.map { FigmaText(text: $0.text, x: $0.x, y: $0.y - offset, w: $0.w, h: $0.h) }
        lifted.children = node.children.map { shiftUp($0, by: offset) }
        return lifted
    }

    // The demo's own background (the full-bleed UIKitPinView), not the clear hosting layers above it.
    private static func hostedBackground(_ host: UIView) -> UIColor? {
        var best: UIColor?
        func scan(_ view: UIView) {
            if let color = view.backgroundColor, color.cgColor.alpha > 0.01,
               view.bounds.width > host.bounds.width * 0.5, view.bounds.height > host.bounds.height * 0.5 {
                best = color
            }
            view.subviews.forEach(scan)
        }
        scan(host)
        return best
    }

    // MARK: General view-tree walk

    private static func viewNodes(in view: UIView, host: UIView) -> [FigmaNode] {
        var nodes: [FigmaNode] = []
        for subview in view.subviews where isVisible(subview) {
            if let leaf = leafNode(subview, host: host) {
                nodes.append(leaf)
            } else if let stack = subview as? UIStackView {
                nodes.append(stackFrame(stack, host: host))
            } else {
                // A rounded, colored view is a shape (a concentric-radius layer / card); emit its fill,
                // then recurse for nested layers and labels.
                if let shape = shapeFillNode(subview, host: host) { nodes.append(shape) }
                nodes.append(contentsOf: viewNodes(in: subview, host: host))
            }
        }
        return nodes.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
    }

    // The leaf mappings: a label/textview to a text node, a control/image/hosted-SwiftUI island to a crop.
    private static func leafNode(_ view: UIView, host: UIView) -> FigmaNode? {
        if let label = view as? UILabel { return labelNode(label, host: host) }
        if let textView = view as? UITextView { return textViewNode(textView, host: host) }
        if isHostingView(view) { return cropNode(view, host: host) }
        return controlNode(view, host: host)
    }

    // One node for an arranged subview of a stack, so the stack keeps a 1:1 child mapping for auto-layout.
    private static func singleNode(_ view: UIView, host: UIView) -> FigmaNode? {
        if let leaf = leafNode(view, host: host) { return leaf }
        if let stack = view as? UIStackView { return stackFrame(stack, host: host) }
        let children = viewNodes(in: view, host: host)
        let shape = shapeFillNode(view, host: host)
        guard shape != nil || !children.isEmpty else { return nil }
        let frame = view.convert(view.bounds, to: host)
        var node = shape ?? FigmaNode(tag: "frame", x: Double(frame.minX), y: Double(frame.minY),
                                      w: Double(frame.width), h: Double(frame.height), children: [])
        node.children = children
        return node
    }

    // A UIStackView is Figma auto-layout: map its axis/spacing/alignment and keep the arranged order.
    private static func stackFrame(_ stack: UIStackView, host: UIView) -> FigmaNode {
        let frame = stack.convert(stack.bounds, to: host)
        let stretches = stack.alignment == .fill
        let children = stack.arrangedSubviews.filter(isVisible).compactMap { view -> FigmaNode? in
            guard var node = singleNode(view, host: host) else { return nil }
            if stretches { node.fillWidth = true }
            return node
        }
        return FigmaNode(
            tag: "frame", x: Double(frame.minX), y: Double(frame.minY), w: Double(frame.width), h: Double(frame.height),
            name: stack.axis == .vertical ? "VStack" : "HStack",
            layout: FigmaLayout(stackLayout(stack)), ordered: true, children: children
        )
    }

    private static func stackLayout(_ stack: UIStackView) -> PinCaptureLayout {
        let axis: PinCaptureLayout.Axis = stack.axis == .vertical ? .column : .row
        let alignment: PinCaptureLayout.CrossAxis
        switch stack.alignment {
        case .trailing, .bottom: alignment = .trailing
        case .center: alignment = .center
        default: alignment = .leading
        }
        return PinCaptureLayout(axis: axis, spacing: stack.spacing, alignment: alignment, mainAxisAlignment: .leading)
    }

    private static func isHostingView(_ view: UIView) -> Bool {
        String(describing: type(of: view)).contains("HostingView")
    }

    // Figma's createImage rejects a crop over 4096px per side and aborts the whole import, so cap the
    // raster scale at whatever keeps the longer side within the limit — never upscaling past the device.
    static func captureScale(for size: CGSize, deviceScale: CGFloat) -> CGFloat {
        min(deviceScale, 4096 / max(size.width, size.height, 1))
    }

    // A colored view with a corner radius is an intentional shape (concentric layer, card); a plain
    // colored container (radius 0) is just layout and would clutter the capture, so require a radius.
    private static func shapeFillNode(_ view: UIView, host: UIView) -> FigmaNode? {
        guard let background = view.backgroundColor, background.cgColor.alpha > 0.01, view.layer.cornerRadius > 0.5 else { return nil }
        let frame = view.convert(view.bounds, to: host)
        let radius = view.layer.cornerRadius
        return FigmaNode(
            tag: "frame", x: Double(frame.minX), y: Double(frame.minY), w: Double(frame.width), h: Double(frame.height),
            fill: RGBA(background), fillToken: PinDisplayListCapture.tokenName(for: background),
            radius: Double(radius), radiusToken: PinFloatTokens.radiusName(for: Double(radius)),
            children: []
        )
    }

    private static func isVisible(_ view: UIView) -> Bool {
        !view.isHidden && view.alpha > 0.01 && view.bounds.width > 1 && view.bounds.height > 1
    }

    // A plain label is a text node; a label with a background (a spacing/radius bar) is a filled, possibly
    // rounded frame wrapping the text.
    private static func labelNode(_ label: UILabel, host: UIView) -> FigmaNode? {
        guard let textNode = textNode(label, host: host) else { return nil }
        guard let background = label.backgroundColor, background.cgColor.alpha > 0.01 else { return textNode }
        let frame = label.convert(label.bounds, to: host)
        let radius = label.layer.cornerRadius
        // An auto-layout frame (not absolute) so the plugin renders the text inline instead of wrapping
        // it in an extra frame. The label's alignment drives where the text sits.
        let justify: PinCaptureLayout.CrossAxis = label.textAlignment == .center ? .center : (label.textAlignment == .right ? .trailing : .leading)
        return FigmaNode(
            tag: "frame", x: Double(frame.minX), y: Double(frame.minY), w: Double(frame.width), h: Double(frame.height),
            fill: RGBA(background), fillToken: PinDisplayListCapture.tokenName(for: background),
            radius: radius > 0.5 ? Double(radius) : nil,
            radiusToken: radius > 0.5 ? PinFloatTokens.radiusName(for: Double(radius)) : nil,
            layout: FigmaLayout(PinCaptureLayout(axis: .row, spacing: 0, alignment: .center, mainAxisAlignment: justify, primaryAxisFixed: true)),
            ordered: true,
            children: [textNode]
        )
    }

    private static func textNode(_ label: UILabel, host: UIView) -> FigmaNode? {
        guard let text = label.text, !text.isEmpty else { return nil }
        let frame = label.convert(label.bounds, to: host)
        // A UILabel in a fill-aligned stack gets a frame far wider than its text; capture the tight text
        // rect (respecting its alignment) so Figma doesn't justify a short string across the whole box.
        let fit = label.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude))
        let width = min(ceil(fit.width), frame.width)
        let height = min(ceil(fit.height), frame.height)
        let originX: CGFloat
        switch label.textAlignment {
        case .center: originX = frame.midX - width / 2
        case .right: originX = frame.maxX - width
        default: originX = frame.minX
        }
        let box = CGRect(x: originX, y: frame.midY - height / 2, width: width, height: height)
        return FigmaNode(
            tag: "text", x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height),
            font: PinDisplayListCapture.figmaFont(label.font, color: label.textColor, underline: false),
            texts: [FigmaText(text: text, x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height))],
            children: []
        )
    }

    // A UITextView is a UIScrollView (so not a cell container); capture its text inset by the text
    // container so the node sits where the glyphs draw.
    private static func textViewNode(_ textView: UITextView, host: UIView) -> FigmaNode? {
        guard let text = textView.text, !text.isEmpty else { return nil }
        let frame = textView.convert(textView.bounds, to: host)
        let inset = textView.textContainerInset
        let padding = textView.textContainer.lineFragmentPadding
        let box = CGRect(
            x: frame.minX + inset.left + padding, y: frame.minY + inset.top,
            width: max(frame.width - inset.left - inset.right - padding * 2, 1),
            height: max(frame.height - inset.top - inset.bottom, 1)
        )
        return FigmaNode(
            tag: "text", x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height),
            font: PinDisplayListCapture.figmaFont(textView.font, color: textView.textColor, underline: false),
            texts: [FigmaText(text: text, x: Double(box.minX), y: Double(box.minY), w: Double(box.width), h: Double(box.height))],
            children: []
        )
    }

    private static func controlNode(_ view: UIView, host: UIView) -> FigmaNode? {
        if view is UISwitch { return cropNode(view, host: host) }
        if let imageView = view as? UIImageView, imageView.image != nil { return cropNode(view, host: host) }
        return nil
    }

    // A control/image/hosted SwiftUI island bakes its appearance into pixels, so crop the live render
    // (front buffer, no screen-update commit — the same discipline the SwiftUI control crop uses).
    private static func cropNode(_ view: UIView, host: UIView) -> FigmaNode? {
        guard view.bounds.width > 1, view.bounds.height > 1 else { return nil }
        let frame = view.convert(view.bounds, to: host)
        let image = autoreleasepool { () -> String? in
            let format = UIGraphicsImageRendererFormat.preferred()
            format.scale = captureScale(for: view.bounds.size, deviceScale: format.scale)
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
            let rendered = renderer.image { _ in view.drawHierarchy(in: view.bounds, afterScreenUpdates: false) }
            return rendered.pngData()?.base64EncodedString()
        }
        guard let image else { return nil }
        return FigmaNode(
            tag: "image", x: Double(frame.minX), y: Double(frame.minY),
            w: Double(frame.width), h: Double(frame.height), image: image, children: []
        )
    }

    // MARK: Cell containers (UITableView / UICollectionView)

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
        var children = viewNodes(in: content, host: host)
        // The disclosure indicator is drawn by the cell outside contentView, so it isn't in the walk.
        // Reconstruct it from the cell's own accessoryType as the SF Symbol chevron the table shows.
        if (cell as? UITableViewCell)?.accessoryType == .disclosureIndicator, let chevron = chevronNode(inRow: frame) {
            children.append(chevron)
        }
        guard !children.isEmpty else { return nil }
        // The cell's own background is the row's fill — for the color demo it IS the swatch.
        let background = (cell.backgroundColor ?? (cell as? UITableViewCell)?.contentView.backgroundColor)
            .flatMap { $0.cgColor.alpha > 0.01 ? $0 : nil }
        return FigmaNode(
            tag: "frame", x: Double(frame.minX), y: Double(frame.minY),
            w: Double(frame.width), h: Double(frame.height),
            fill: background.map(RGBA.init), fillToken: background.flatMap(PinDisplayListCapture.tokenName(for:)),
            name: "Row", children: children
        )
    }

    private static func chevronNode(inRow row: CGRect) -> FigmaNode? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        guard let symbol = UIImage(systemName: "chevron.right", withConfiguration: configuration)?
            .withTintColor(.secondaryText, renderingMode: .alwaysOriginal) else { return nil }
        let image = autoreleasepool {
            UIGraphicsImageRenderer(size: symbol.size).image { _ in symbol.draw(at: .zero) }.pngData()?.base64EncodedString()
        }
        guard let image else { return nil }
        let box = CGRect(x: row.maxX - .spacingL - symbol.size.width, y: row.midY - symbol.size.height / 2,
                         width: symbol.size.width, height: symbol.size.height)
        return FigmaNode(tag: "image", x: Double(box.minX), y: Double(box.minY),
                         w: Double(box.width), h: Double(box.height), image: image, children: [])
    }

    // The table draws hairline separators between cells (not in any cell's tree). Reconstruct them from
    // the table's own separatorColor at the row boundaries, inset to match the cells.
    private static func separatorNodes(between rows: [FigmaNode], table: UITableView?) -> [FigmaNode] {
        guard let color = table?.separatorColor, rows.count > 1 else { return [] }
        let inset = CGFloat.spacingL
        return rows.dropLast().enumerated().map { index, row in
            let next = rows[index + 1]
            return FigmaNode(
                tag: "frame", x: row.x + Double(inset), y: next.y - 0.5,
                w: row.w - Double(inset), h: 1,
                fill: RGBA(color), fillToken: PinDisplayListCapture.tokenName(for: color),
                name: "Separator", children: []
            )
        }
    }
}
