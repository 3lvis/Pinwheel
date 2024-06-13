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

    private var subviewSafeBottomConstraint = [NSLayoutConstraint]()
    private var subviewKeyboardBottomConstraint = [NSLayoutConstraint]()

    private func baseSetup() {
        backgroundColor = .primaryBackground
        translatesAutoresizingMaskIntoConstraints = false

        setupSafeKeyboardNotifications()
    }

    open func setup() {
    }

    public func safeAnchorToKeyboardTopAndSafeAreaBottom(subview: UIView, constant: CGFloat = 0) {
        subviewKeyboardBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: constant))
        subviewSafeBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: constant))
        NSLayoutConstraint.deactivate(subviewKeyboardBottomConstraint)
        NSLayoutConstraint.activate(subviewSafeBottomConstraint)
    }

    public func safeAnchorToKeyboardTopAndSuperviewBottom(subview: UIView, constant: CGFloat = 0) {
        subviewKeyboardBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: constant))
        subviewSafeBottomConstraint.append(subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: constant))
        NSLayoutConstraint.deactivate(subviewKeyboardBottomConstraint)
        NSLayoutConstraint.activate(subviewSafeBottomConstraint)
    }

    private func setupSafeKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(safeKeyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(safeKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func safeKeyboardWillShow(_ notification: NSNotification) {
        guard !subviewSafeBottomConstraint.isEmpty && !subviewKeyboardBottomConstraint.isEmpty else { return }
        NSLayoutConstraint.deactivate(subviewSafeBottomConstraint)
        NSLayoutConstraint.activate(subviewKeyboardBottomConstraint)
        self.layoutIfNeeded()
    }

    @objc private func safeKeyboardWillHide(_ notification: NSNotification) {
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
