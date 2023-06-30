import UIKit

open class View: UIView {
    public init() {
        super.init(frame: .zero)
        baseSetup()
        setup()
    }

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

    func baseSetup() {
        backgroundColor = .primaryBackground
        translatesAutoresizingMaskIntoConstraints = false
    }

    open func setup() {
    }
}
