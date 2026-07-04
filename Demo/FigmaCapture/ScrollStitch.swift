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

    struct Page {
        let image: UIImage
        let offset: CGFloat
        let height: CGFloat
    }

    // Returns one image per viewport page (not a single stitched image): Figma's createImage caps
    // at 4096px per side, and a long list stitched whole blows past it. A page is viewport-tall, so
    // each stays well under the cap; placed at its offset the pages reproduce the full list.
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
            // layoutIfNeeded forces the newly-revealed cells to lay out synchronously (a real hook,
            // not a guess); a short settle then covers only their draw, which has no callback.
            scrollView.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 100_000_000)
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
