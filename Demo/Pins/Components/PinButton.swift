import Pinwheel

public extension CGFloat {
    static let buttonHeight: CGFloat = 50
}

class PinButton: View {
    var primary: Button!
    var primaryDisabled: Button!
    var primaryLoading: Button!
    var primaryTitleAndSymbol: Button!
    var primarySymbolOnly: Button!
    var secondary: Button!
    var tertiary: Button!
    var custom: Button!

    override func setup() {
        primary = Button(title: "Press me")
        primary.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        primaryDisabled = Button(title: "Save")
        primaryDisabled.isEnabled = false

        primaryLoading = Button(title: "Saving")
        primaryLoading.showActivityIndicator(true)
        primaryLoading.addTarget(self, action: #selector(loadingPressed(_:)), for: .touchUpInside)

        primaryTitleAndSymbol = Button(title: "Continue", symbol: "arrow.right")
        primarySymbolOnly = Button(symbol: "arrow.right")

        secondary = Button(title: "Long toggle loading", style: .secondary)
        secondary.addTarget(self, action: #selector(loading), for: .touchUpInside)

        let secondaryDisabled = Button(title: "Disabled", style: .secondary)
        secondaryDisabled.isEnabled = false

        tertiary = Button(title: "Update titles", style: .tertiary)
        tertiary.addTarget(self, action: #selector(updateTitles), for: .touchUpInside)

        let tertiaryDisabled = Button(title: "Disabled", style: .tertiary)
        tertiaryDisabled.isEnabled = false

        custom = Button(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        custom.addTarget(self, action: #selector(shrinkTitles), for: .touchUpInside)

        let customDisabled = Button(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        customDisabled.isEnabled = false

        let stackView = UIStackView(axis: .vertical, spacing: .spacingM, alignment: .center)
        stackView.addArrangedSubviews([
            primary,
            primaryDisabled,
            primaryLoading,
            primaryTitleAndSymbol,
            primarySymbolOnly,
            secondary,
            secondaryDisabled,
            tertiary,
            tertiaryDisabled,
            custom,
            customDisabled
        ])
        addSubview(stackView)
        stackView.anchorToTopSafeArea(margin: .spacingXXL)
    }

    @objc func loadingPressed(_ button: Button) {
        guard !button.isLoading else { return }

        print("Loading pressed")
    }

    @objc func updateTitles() {
        primary.title = "Long Updated action"
        secondary.title = "Long Updated bordered"
        tertiary.title = "Long Updated link"
    }

    @objc func shrinkTitles() {
        primary.title = "Press me"
        secondary.title = "Long Toggle loading"
        tertiary.title = "Update title"
    }

    @objc func tapped() {
        primaryDisabled.isEnabled = !primaryDisabled.isEnabled
    }

    @objc func loading() {
        primaryLoading.title = primaryLoading.isLoading ? "Save" : "Saving"
        primaryLoading.showActivityIndicator(!primaryLoading.isLoading)
    }
}
