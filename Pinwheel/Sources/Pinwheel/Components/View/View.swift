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

    var subviewSafeBottomConstraint = [NSLayoutConstraint]()
    var subviewKeyboardBottomConstraint = [NSLayoutConstraint]()

    func baseSetup() {
        backgroundColor = .primaryBackground
        translatesAutoresizingMaskIntoConstraints = false

        setupKeyboardNotifications()
    }

    open func setup() {
    }

    public func safeAnchorToKeyboardTopGuide(subview: UIView, constant: CGFloat) {
        subviewKeyboardBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: constant))
        subviewSafeBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: constant))
        NSLayoutConstraint.deactivate(subviewKeyboardBottomConstraint)
        NSLayoutConstraint.activate(subviewSafeBottomConstraint)
    }

    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(_ notification: NSNotification) {
        guard !subviewSafeBottomConstraint.isEmpty && !subviewKeyboardBottomConstraint.isEmpty else { return }
        NSLayoutConstraint.deactivate(subviewSafeBottomConstraint)
        NSLayoutConstraint.activate(subviewKeyboardBottomConstraint)
        self.layoutIfNeeded()
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        guard !subviewSafeBottomConstraint.isEmpty && !subviewKeyboardBottomConstraint.isEmpty else { return }
        NSLayoutConstraint.deactivate(subviewKeyboardBottomConstraint)
        NSLayoutConstraint.activate(subviewSafeBottomConstraint)
        self.layoutIfNeeded()
    }

    deinit {
        subviewSafeBottomConstraint.removeAll()
        subviewKeyboardBottomConstraint.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
}
