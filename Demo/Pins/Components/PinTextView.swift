import Pinwheel

class PinTextView: View {
    lazy var rightAnchoredLabel: Label = {
        let label = Label()
        label.text = "Right Label"
        label.textAlignment = .right
        return label
    }()

    lazy var leftAnchoredLabel: Label = {
        let label = Label()
        label.text = "Left Label"
        label.textAlignment = .right
        return label
    }()

    override func setup() {
        let textView = UITextView(withAutoLayout: true)
        textView.returnKeyType = .done
        textView.delegate = self
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

extension PinTextView: UITextViewDelegate {
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
