import UIKit
import Pinwheel

class UIKitPinButtonExample: UIKitPinView {
    var primary: UIKitPinButton!
    var primaryDisabled: UIKitPinButton!
    var primaryLoading: UIKitPinButton!
    var primaryLoadingDisabled: UIKitPinButton!
    var primaryTitleAndSymbol: UIKitPinButton!
    var primarySymbolOnly: UIKitPinButton!
    var secondary: UIKitPinButton!
    var tertiary: UIKitPinButton!
    var custom: UIKitPinButton!
    var primaryFloating: UIKitPinButton!

    override func setup() {
        primary = UIKitPinButton(title: "Press me")
        primary.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        primaryDisabled = UIKitPinButton(title: "Save")
        primaryDisabled.isEnabled = false

        primaryLoading = UIKitPinButton(title: "Saving")
        primaryLoading.showActivityIndicator(true)
        primaryLoading.addTarget(self, action: #selector(loadingPressed(_:)), for: .touchUpInside)

        primaryLoadingDisabled = UIKitPinButton(title: "Saving")
        primaryLoadingDisabled.isEnabled = false
        primaryLoadingDisabled.showActivityIndicator(true)

        primaryTitleAndSymbol = UIKitPinButton(title: "Continue", symbol: "arrow.right")
        primarySymbolOnly = UIKitPinButton(symbol: "arrow.right")

        secondary = UIKitPinButton(title: "Long toggle loading", style: .secondary)
        secondary.addTarget(self, action: #selector(loading), for: .touchUpInside)

        let secondaryDisabled = UIKitPinButton(title: "Disabled", style: .secondary)
        secondaryDisabled.isEnabled = false

        tertiary = UIKitPinButton(title: "Update titles", style: .tertiary)
        tertiary.addTarget(self, action: #selector(updateTitles), for: .touchUpInside)

        let tertiaryDisabled = UIKitPinButton(title: "Disabled", style: .tertiary)
        tertiaryDisabled.isEnabled = false

        custom = UIKitPinButton(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        custom.addTarget(self, action: #selector(shrinkTitles), for: .touchUpInside)

        let customDisabled = UIKitPinButton(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        customDisabled.isEnabled = false

        primaryFloating = UIKitPinButton(title: "Continue")

        let stackView = UIStackView(axis: .vertical, spacing: .spacingM, alignment: .center)
        stackView.addArrangedSubviews([
            primary,
            primaryDisabled,
            primaryLoading,
            primaryLoadingDisabled,
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

        addSubview(primaryFloating)
        NSLayoutConstraint.activate([
            primaryFloating.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: .spacingM),
            primaryFloating.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -.spacingM),
            primaryFloating.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -.spacingM)
        ])
    }

    @objc func loadingPressed(_ button: UIKitPinButton) {
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

        primaryLoadingDisabled.isEnabled = !primaryLoadingDisabled.isEnabled

        primaryFloating.showActivityIndicator(!primaryFloating.isLoading)
    }
}
