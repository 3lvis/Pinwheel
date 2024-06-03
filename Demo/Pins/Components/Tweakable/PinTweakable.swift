import Pinwheel

class PinTweakable: View, Tweakable {
    lazy var tweaks: [Tweak] = {
        var options = [Tweak]()

        let option1 = TextTweak(title: "Option 1") {
            self.titleLabel.text = "Choosen Option 1!\n\nYou can drag the button too :D"
        }

        let option2 = TextTweak(title: "Option 2", description: "Description 2") {
            self.titleLabel.text = "Choosen Option 2!\n\nYou can drag the button too :D"
        }

        let option3 = BoolTweak(title: "Option 3") { isOn in
            self.titleLabel.text = "Choosen Option 3!\n\n \(isOn ? "is on" : "is off")"
        }
        
        return [option1, option2, option3]
    }()

    lazy var titleLabel: Label = {
        let label = Label(style: .body)
        label.text = "Tap the button and choose and option ✨"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func setup() {
        addSubview(titleLabel)
        titleLabel.fillInSuperview(margin: .spacingXXL)
    }
}
