import UIKit

open class View: UIView {
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
