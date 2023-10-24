import Pinwheel

class PinTweakable: View, Tweakable {
    lazy var tweaks: [Tweak] = {
        var options = [Tweak]()

        options.append(TextTweak(title: "Option 1", description: nil) { [weak self] _ in
            self?.titleLabel.text = "Choosen Option 1!\n\nYou can drag the button too :D"
        })

        options.append(TextTweak(title: "Option 2", description: "Description 2") { [weak self] _ in
            self?.titleLabel.text = "Choosen Option 2!\n\nYou can drag the button too :D"
        })

        options.append(BoolTweak(title: "Option 3") { [weak self] isOn in
            let value = isOn as? Bool ?? false
            self?.titleLabel.text = "Choosen Option 3!\n\n \(value ? "is on" : "is off")"
        })

        return options
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
        titleLabel.fillInSuperview(margin: .spacingXL)
    }
}
