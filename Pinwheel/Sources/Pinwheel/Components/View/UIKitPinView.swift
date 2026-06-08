import UIKit

/// Intentional UIKit surface (not a thin host over SwiftUI). This base view
/// exists for open subclassing and the `setup()` lifecycle hook that UIKit
/// example/screen code relies on — there is no comparable SwiftUI seam to bridge.
open class UIKitPinView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        baseSetup()
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        baseSetup()
        setup()
    }

    private func baseSetup() {
        backgroundColor = .primaryBackground
        translatesAutoresizingMaskIntoConstraints = false
    }

    open func setup() {
    }
}
