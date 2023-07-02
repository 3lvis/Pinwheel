import Pinwheel

class TweakablePinwheelView: View, Tweakable {
    lazy var tweakingOptions: [TweakingOption] = {
        var options = [TweakingOption]()

        options.append(TweakingOption(title: "Option 1", description: nil) { [weak self] in
            self?.titleLabel.text = "Choosen Option 1!\n\nYou can drag the button too :D"
        })

        options.append(TweakingOption(title: "Option 2", description: nil) { [weak self] in
            self?.titleLabel.text = "Choosen Option 2!\n\nYou can drag the button too :D"
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
