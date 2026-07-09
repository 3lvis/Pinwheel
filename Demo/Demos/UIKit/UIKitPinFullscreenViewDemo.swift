import UIKit
import Pinwheel

class UIKitPinFullscreenViewDemo: UIKitPinFullscreenView {
    lazy var rightAnchoredLabel: UIKitPinLabel = {
        let label = UIKitPinLabel()
        label.text = "Right Label"
        label.textAlignment = .right
        return label
    }()

    lazy var leftAnchoredLabel: UIKitPinLabel = {
        let label = UIKitPinLabel()
        label.text = "Left Label"
        label.textAlignment = .right
        return label
    }()

    override func setup() {
        let textView = UITextView(withAutoLayout: true)
        textView.returnKeyType = .done
        textView.delegate = self
        textView.font = .body
        textView.textColor = .primaryText
        textView.backgroundColor = .clear
        textView.text = """
        UIKitPinFullscreenView is a UIKit base class for keyboard-aware full-screen \
        screens (forms, composers, editors). Subclass it, override setup(), and anchor \
        bottom content with safeAnchorToKeyboardTopAndSafeAreaBottom(subview:).

        Edit this text: the two labels below ride up above the keyboard while editing, \
        and drop back to the safe-area bottom when it dismisses (tap Return). It also \
        gives a viewDidFirstAppear() lifecycle hook a bare UIView lacks.

        SwiftUI needs no equivalent — keyboard avoidance and onAppear are built in — \
        which is why this stays a UIKit-only surface.
        """
        addSubview(textView)
        addSubview(rightAnchoredLabel)
        addSubview(leftAnchoredLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .spacingM),
            textView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -.spacingM),

            leftAnchoredLabel.topAnchor.constraint(equalTo: textView.bottomAnchor),
            leftAnchoredLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: .spacingM),

            rightAnchoredLabel.topAnchor.constraint(equalTo: textView.bottomAnchor),
            rightAnchoredLabel.leadingAnchor.constraint(equalTo: leftAnchoredLabel.trailingAnchor, constant: .spacingM),
            rightAnchoredLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -.spacingM),
        ])

        safeAnchorToKeyboardTopAndSafeAreaBottom(subview: rightAnchoredLabel, constant: -.spacingM)
        safeAnchorToKeyboardTopAndSafeAreaBottom(subview: leftAnchoredLabel, constant: -.spacingM)
    }
}

extension UIKitPinFullscreenViewDemo: UITextViewDelegate {
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
