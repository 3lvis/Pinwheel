import UIKit

/// Base view for open subclassing; override `setup()` for post-init configuration.
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
