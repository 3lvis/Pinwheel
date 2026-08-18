import QuartzCore
import UIKit

/// A text recording of a session someone drove by hand: what they touched, what the tray decided, and
/// where everything stood in between. Started with `-PinwheelRecord`, written to `session.log` in the
/// app's temporary directory, and off entirely without the argument.
///
/// It exists so a person can say "watch this" instead of describing it.
public enum PinwheelRecorder {
    private static var session: Session?

    /// Call once at launch. Does nothing unless `-PinwheelRecord` was passed.
    public static func start() {
        guard ProcessInfo.processInfo.arguments.contains("-PinwheelRecord") else { return }
        session = Session()
        note("build", "\(PinwheelBuild.label)  \(PinwheelBuild.detail)")
    }

    /// Something the code decided, in its own words. Free-form, because what is worth recording changes
    /// with whatever is being chased.
    static func note(_ category: String, _ message: String) {
        session?.write(category, message)
    }

    /// Values to follow continuously. Only changes are written, so a session spent sitting still costs
    /// nothing to read.
    static func follow(_ sample: @escaping () -> [(String, CGFloat)]) {
        session?.follow(sample)
    }

    /// One sample closure at a time, so a second follower means a second of whatever follows.
    static func noteIfAlreadyFollowing(_ who: String) {
        session?.noteIfFollowing(who)
    }

    static func stopFollowing() {
        session?.follow(nil)
    }

    private final class Session: NSObject {
        private let handle: FileHandle?
        private let start = CACurrentMediaTime()
        private var link: CADisplayLink?
        private var sample: (() -> [(String, CGFloat)])?
        private var previous: [(String, CGFloat)] = []
        private var watched: [ObjectIdentifier] = []

        private static func openForAppending(_ path: String) -> FileHandle? {
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil)
            }
            let handle = FileHandle(forWritingAtPath: path)
            handle?.seekToEndOfFile()
            return handle
        }

        override init() {
            handle = Session.openForAppending(NSTemporaryDirectory() + "session.log")
            super.init()

            let screen = UIScreen.main.bounds
            write("session", "=== launched  screen=\(Int(screen.width))x\(Int(screen.height))")

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowBecameVisible),
                name: UIWindow.didBecomeVisibleNotification,
                object: nil
            )
            for name in [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillHideNotification] {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyboardAnnouncedItsMove),
                    name: name,
                    object: nil
                )
            }
        }

        @objc private func windowBecameVisible(_ notification: Notification) {
            (notification.object as? UIWindow).map { watch($0) }
        }

        @objc private func keyboardAnnouncedItsMove(_ notification: Notification) {
            let end = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            let showing = notification.name == UIResponder.keyboardWillShowNotification
            write("keyboard", "\(showing ? "will show" : "will hide") top=\(Int(end?.minY ?? -1))")
        }

        func write(_ category: String, _ message: String) {
            let line = String(format: "%8.3f  %-9@  %@", CACurrentMediaTime() - start, category as NSString, message as NSString)
            handle?.write(Data((line + "\n").utf8))
        }

        func noteIfFollowing(_ who: String) {
            guard sample != nil else { return }
            write("session", "\(who) began following while something else still was — two are on screen")
        }

        func follow(_ sample: (() -> [(String, CGFloat)])?) {
            self.sample = sample
            previous = []
            link?.invalidate()
            guard sample != nil else { return link = nil }
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        @objc private func tick() {
            guard let values = sample?() else { return }
            let moved = values.count != previous.count
                || zip(values, previous).contains { abs($0.1 - $1.1) > 0.5 }
            guard moved else { return }
            previous = values
            write("geometry", values.map { "\($0.0)=\(Int($0.1.rounded()))" }.joined(separator: " "))
        }

        /// A recogniser that never leaves `.possible` sees every touch and swallows none of them.
        private func watch(_ window: UIWindow) {
            let id = ObjectIdentifier(window)
            guard !watched.contains(id) else { return }
            watched.append(id)
            let watcher = TouchWatcher { [weak self] phase, point, view in
                self?.write("touch", "\(phase) (\(Int(point.x)),\(Int(point.y)))\(view.map { "  \($0)" } ?? "")")
            }
            window.addGestureRecognizer(watcher)
            write("session", "watching a window \(Int(window.bounds.width))x\(Int(window.bounds.height))")
        }
    }

    private final class TouchWatcher: UIGestureRecognizer {
        private let report: (String, CGPoint, String?) -> Void

        init(report: @escaping (String, CGPoint, String?) -> Void) {
            self.report = report
            super.init(target: nil, action: nil)
            cancelsTouchesInView = false
            delaysTouchesBegan = false
            delaysTouchesEnded = false
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            announce("down", touches)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            announce("move", touches)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            announce("up", touches)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            announce("cancel", touches)
        }

        private func announce(_ phase: String, _ touches: Set<UITouch>) {
            guard let touch = touches.first, let watchedWindow = view else { return }
            let point = touch.location(in: watchedWindow)
            report(
                phase,
                point,
                phase == "down"
                    ? name(watchedWindow.hitTest(point, with: nil), at: point, under: watchedWindow)
                    : nil
            )
        }

        /// What a person would call the thing they touched. SwiftUI puts its identifiers in the
        /// accessibility tree rather than on views, so a plain view walk answers `_UIHostingView` for
        /// every tap in the app — the smallest labelled accessibility element under the finger is the
        /// thing that was actually pressed.
        private func name(_ hit: UIView?, at point: CGPoint, under host: UIView) -> String? {
            var best: (area: CGFloat, name: String)?

            func consider(_ node: AnyObject) {
                let frame = node.accessibilityFrame ?? .zero
                let area = frame.width * frame.height
                if area > 0, frame.contains(point) {
                    let identifier = node.accessibilityIdentifier ?? nil
                    let label = node.accessibilityLabel ?? nil
                    if let found = (identifier?.isEmpty == false ? identifier : label), !found.isEmpty,
                       best == nil || area < best!.area {
                        best = (area, found)
                    }
                }
                (node.accessibilityElements ?? nil)?.forEach { consider($0 as AnyObject) }
                (node as? UIView)?.subviews.forEach { consider($0) }
            }
            consider(host)
            if let best { return best.name }

            guard let hit else { return nil }
            var view: UIView? = hit
            while let candidate = view {
                if let identifier = candidate.accessibilityIdentifier, !identifier.isEmpty { return identifier }
                view = candidate.superview
            }
            return String(describing: type(of: hit))
        }
    }
}
