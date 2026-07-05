import UIKit

// Captures a lazy scroll view in full by paging it and stitching each page: lazy rows don't exist
// until scrolled into view, and the finite data source makes the paging terminate.
enum ScrollStitch {
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

    struct Page {
        let image: UIImage
        let offset: CGFloat
        let height: CGFloat
    }

    // One image per viewport page, not one stitched image: Figma's createImage caps at 4096px/side,
    // which a long list would exceed.
    @MainActor
    static func capture(_ scrollView: UIScrollView, in window: UIWindow) async -> (pages: [Page], size: CGSize)? {
        let scale = window.screen.scale
        let frame = scrollView.convert(scrollView.bounds, to: window)
        let viewport = scrollView.bounds.height
        let total = max(scrollView.contentSize.height, viewport)
        guard frame.width > 1, viewport > 1 else { return nil }

        let restore = scrollView.contentOffset
        var pages: [Page] = []
        var target: CGFloat = 0
        var iterations = 0
        while iterations < 200 {
            iterations += 1
            scrollView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            // layoutIfNeeded lays out the newly-revealed cells synchronously; the page crop's
            // drawHierarchy(afterScreenUpdates: true) then flushes their draw — no timed settle.
            scrollView.layoutIfNeeded()
            // The scroll view clamps past its max offset, so read where it actually landed and
            // place the page there — the last page overlaps the previous with identical pixels.
            let actual = scrollView.contentOffset.y
            let pageHeight = min(viewport, total - actual)
            let shot = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            if let cgImage = shot.cgImage {
                let crop = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                                  width: frame.width * scale, height: pageHeight * scale)
                if let cropped = cgImage.cropping(to: crop) {
                    pages.append(Page(image: UIImage(cgImage: cropped), offset: actual, height: pageHeight))
                }
            }
            if actual + viewport >= total { break }
            target += viewport
        }
        scrollView.setContentOffset(restore, animated: false)
        return (pages, CGSize(width: frame.width, height: total))
    }
}
