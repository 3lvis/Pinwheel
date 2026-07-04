import UIKit

// Captures a lazy scroll view (List / UITableView) in full by scrolling it top-to-bottom and
// stitching each page's on-screen pixels into one tall image. Lazy rows don't exist until scrolled
// into view, but the data source is finite, so paging over contentSize terminates and reaches every
// row. Ugly by necessity — it drives real scrolling and reads the rendered window — but it's the
// only way to get below-the-fold lazy content, which no layout-anchor pass can see.
enum ScrollStitch {
    // Deepest-first search for the scroll view backing the list (a SwiftUI List is a
    // UICollectionView; UIKitPinTableView wraps a UITableView), preferring the tallest content.
    static func scrollView(in root: UIView) -> UIScrollView? {
        var best: UIScrollView?
        func walk(_ view: UIView) {
            for subview in view.subviews {
                if let scroll = subview as? UIScrollView,
                   scroll.contentSize.height > (best?.contentSize.height ?? 0) {
                    best = scroll
                }
                walk(subview)
            }
        }
        walk(root)
        return best
    }

    @MainActor
    static func capture(_ scrollView: UIScrollView, in window: UIWindow) async -> (image: UIImage, size: CGSize)? {
        let scale = window.screen.scale
        let frame = scrollView.convert(scrollView.bounds, to: window)
        let viewport = scrollView.bounds.height
        let total = max(scrollView.contentSize.height, viewport)
        guard frame.width > 1, viewport > 1 else { return nil }

        let restore = scrollView.contentOffset
        var pages: [(image: UIImage, y: CGFloat, height: CGFloat)] = []
        var offset: CGFloat = 0
        while offset < total {
            scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            // Let the newly-revealed cells lay out and draw before snapshotting.
            try? await Task.sleep(nanoseconds: 250_000_000)
            let pageHeight = min(viewport, total - offset)
            let shot = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            if let cgImage = shot.cgImage {
                let crop = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                                  width: frame.width * scale, height: pageHeight * scale)
                if let cropped = cgImage.cropping(to: crop) {
                    pages.append((UIImage(cgImage: cropped), offset, pageHeight))
                }
            }
            offset += viewport
        }
        scrollView.setContentOffset(restore, animated: false)

        let size = CGSize(width: frame.width, height: total)
        let stitched = UIGraphicsImageRenderer(size: size).image { _ in
            for page in pages {
                page.image.draw(in: CGRect(x: 0, y: page.y, width: frame.width, height: page.height))
            }
        }
        return (stitched, size)
    }
}
