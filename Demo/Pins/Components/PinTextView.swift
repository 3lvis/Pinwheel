import Pinwheel

class PinTextView: View {
    override func setup() {
        let textView = UITextView(withAutoLayout: true)
        addSubview(textView)
        textView.fillInSuperview()
    }
}
