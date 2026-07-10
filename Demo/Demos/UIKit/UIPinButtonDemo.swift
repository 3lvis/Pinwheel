import UIKit
import Pinwheel

class UIPinButtonDemo: UIPinView {
    var primary: UIPinButton!
    var primaryDisabled: UIPinButton!
    var primaryLoading: UIPinButton!
    var primaryLoadingDisabled: UIPinButton!
    var primaryTitleAndSymbol: UIPinButton!
    var primarySymbolOnly: UIPinButton!
    var secondary: UIPinButton!
    var tertiary: UIPinButton!
    var custom: UIPinButton!
    var primaryFloating: UIPinButton!

    override func setup() {
        primary = UIPinButton(title: "Press me")
        primary.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        primaryDisabled = UIPinButton(title: "Save")
        primaryDisabled.isEnabled = false

        primaryLoading = UIPinButton(title: "Saving")
        primaryLoading.showActivityIndicator(true)
        primaryLoading.addTarget(self, action: #selector(loadingPressed(_:)), for: .touchUpInside)

        primaryLoadingDisabled = UIPinButton(title: "Saving")
        primaryLoadingDisabled.isEnabled = false
        primaryLoadingDisabled.showActivityIndicator(true)

        primaryTitleAndSymbol = UIPinButton(title: "Continue", systemImage: "arrow.right")
        primarySymbolOnly = UIPinButton(systemImage: "arrow.right")

        secondary = UIPinButton(title: "Long toggle loading", style: .secondary)
        secondary.addTarget(self, action: #selector(loading), for: .touchUpInside)

        let secondaryDisabled = UIPinButton(title: "Disabled", style: .secondary)
        secondaryDisabled.isEnabled = false

        tertiary = UIPinButton(title: "Update titles", style: .tertiary)
        tertiary.addTarget(self, action: #selector(updateTitles), for: .touchUpInside)

        let tertiaryDisabled = UIPinButton(title: "Disabled", style: .tertiary)
        tertiaryDisabled.isEnabled = false

        custom = UIPinButton(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        custom.addTarget(self, action: #selector(shrinkTitles), for: .touchUpInside)

        let customDisabled = UIPinButton(title: "Custom", font: .caption, style: .custom(textColor: .green, backgroundColor: .red))
        customDisabled.isEnabled = false

        primaryFloating = UIPinButton(title: "Continue")

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

    @objc func loadingPressed(_ button: UIPinButton) {
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
