import UIKit

extension UIViewController {
    // UIKit wants these three in this order: the child is told it is leaving while it still has a
    // parent, and only then is the containment undone. Calling `removeFromParent()` first leaves the
    // child never having heard `willMove(toParent: nil)`, which is the shape that leaks a hosting
    // controller's view alive inside a hierarchy that has forgotten it.
    // Three call sites, two of which oida cannot see: it counts a call through a subclass instance
    // (`hosting.detachFromParent()`, where hosting is a UIHostingController) against that subclass rather
    // than against this extension, and so reads three callers as one — kolonialno/oida-swift#56.
    // oida:disable:next no_single_use_void_functions
    func detachFromParent() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
