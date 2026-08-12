import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class PinwheelThemeTests: XCTestCase {
    private struct FlatColorProvider: ColorProvider {
        let color: UIColor
        var primaryText: UIColor { color }
        var secondaryText: UIColor { color }
        var tertiaryText: UIColor { color }
        var actionText: UIColor { color }
        var criticalText: UIColor { color }
        var primaryBackground: UIColor { color }
        var secondaryBackground: UIColor { color }
        var actionBackground: UIColor { color }
        var criticalBackground: UIColor { color }
    }

    private struct FixedSizeFontProvider: FontProvider {
        let size: CGFloat
        var title: UIFont { font(ofSize: size, weight: .regular) }
        var subtitle: UIFont { font(ofSize: size, weight: .regular) }
        var subtitleSemibold: UIFont { font(ofSize: size, weight: .semibold) }
        var body: UIFont { font(ofSize: size, weight: .regular) }
        var footnote: UIFont { font(ofSize: size, weight: .regular) }
        var caption: UIFont { font(ofSize: size, weight: .regular) }

        func font(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
            UIFont.systemFont(ofSize: size, weight: weight)
        }
    }

    private func theme(named name: String, color: UIColor, fontSize: CGFloat) -> PinwheelTheme {
        PinwheelTheme(
            name: name,
            colors: FlatColorProvider(color: color),
            fonts: FixedSizeFontProvider(size: fontSize)
        )
    }

    func testColorTokenResolvesTheThemeInTheTraitCollectionRatherThanAGlobal() {
        let red = theme(named: "Red", color: .red, fontSize: 10)
        let blue = theme(named: "Blue", color: .blue, fontSize: 10)

        let inRed = UIColor.primaryText.resolvedColor(with: UITraitCollection(mutations: {
            $0[PinwheelThemeTrait.self] = red
        }))
        let inBlue = UIColor.primaryText.resolvedColor(with: UITraitCollection(mutations: {
            $0[PinwheelThemeTrait.self] = blue
        }))

        XCTAssertEqual(inRed, UIColor.red, "a color token must resolve the theme carried by the traits it is resolved against")
        XCTAssertEqual(inBlue, UIColor.blue, "the same token must resolve differently under a different theme — one static provider cannot be brand-reactive")
    }

    func testFontTokenResolvesThePassedTheme() {
        let small = theme(named: "Small", color: .red, fontSize: 11)
        let large = theme(named: "Large", color: .red, fontSize: 29)

        XCTAssertEqual(PinTextStyle.body.uiFont(in: small).pointSize, 11)
        XCTAssertEqual(PinTextStyle.body.uiFont(in: large).pointSize, 29, "a text style must read the theme it is given, not a fixed provider")
    }

    func testThemesAreEqualByNameSoAReRenderSkipsAnUnchangedSelection() {
        let first = theme(named: "Marine", color: .red, fontSize: 10)
        let second = theme(named: "Marine", color: .blue, fontSize: 20)
        XCTAssertEqual(first, second, "a theme is identified by its name — the providers are its contents, not its identity")
    }

    func testChromeResolvesTheSelectedThemeByName() {
        let chrome = PinwheelChrome()
        chrome.themes = [theme(named: "Marine", color: .red, fontSize: 10), theme(named: "Ember", color: .blue, fontSize: 10)]
        chrome.selectedThemeName = "Ember"
        XCTAssertEqual(chrome.theme.name, "Ember")
    }

    func testChromeFallsBackToTheFirstThemeWhenThePersistedNameIsGone() {
        let chrome = PinwheelChrome()
        chrome.themes = [theme(named: "Marine", color: .red, fontSize: 10)]
        chrome.selectedThemeName = "Ember"
        chrome.normalizeTheme()
        XCTAssertEqual(chrome.selectedThemeName, "Marine", "a persisted name for a theme no longer supplied must fall back rather than resolve nothing")
    }

    func testAThemeKeepsRoundedButtonsUnlessItAsksForAnotherShape() {
        XCTAssertEqual(theme(named: "Marine", color: .red, fontSize: 10).buttonShape, .rounded)
    }

    func testAThemeCanGiveItsButtonsACapsule() {
        let capsuled = PinwheelTheme(
            name: "Ember",
            colors: FlatColorProvider(color: .red),
            fonts: FixedSizeFontProvider(size: 10),
            buttonShape: .capsule
        )
        XCTAssertEqual(capsuled.buttonShape, .capsule, "a capsule is half the button's height, so it cannot be carried as a radius")
    }

    // A detached view never recomputes its trait collection, so a themed window is the only
    // place a UIKit token resolves at all.
    private func windowShowing(_ view: UIView, in theme: PinwheelTheme) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.traitOverrides[PinwheelThemeTrait.self] = theme
        view.frame = window.bounds
        window.addSubview(view)
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }

    func testAUIKitLabelTakesItsFontFromTheThemeItIsShownIn() {
        let label = UIPinLabel(font: .body)
        let window = windowShowing(label, in: theme(named: "Large", color: .red, fontSize: 29))
        withExtendedLifetime(window) {
            XCTAssertEqual(
                label.font.pointSize,
                29,
                "a UIKit label must resolve its font against the theme it is shown in, not the one current when it was built"
            )
        }
    }

    func testAUIKitLabelFollowsALaterThemeChange() {
        let label = UIPinLabel(font: .body)
        let window = windowShowing(label, in: theme(named: "Small", color: .red, fontSize: 11))
        withExtendedLifetime(window) {
            XCTAssertEqual(label.font.pointSize, 11)
            window.traitOverrides[PinwheelThemeTrait.self] = theme(named: "Large", color: .red, fontSize: 29)
            window.layoutIfNeeded()
            XCTAssertEqual(label.font.pointSize, 29, "switching theme must restyle a label already on screen")
        }
    }

    func testATableViewCellLabelTakesItsFontFromTheThemeItIsShownIn() {
        let cell = UIPinTableViewCell(style: .default, reuseIdentifier: nil)
        let window = windowShowing(cell, in: theme(named: "Large", color: .red, fontSize: 29))
        withExtendedLifetime(window) {
            XCTAssertEqual(cell.titleLabel.font.pointSize, 29, "a cell's labels are themed like any other")
        }
    }

    func testATableViewCellSwitchTakesTheThemesActionColorNotAppleGreen() {
        let cell = UIPinTableViewCell(style: .default, reuseIdentifier: nil)
        let window = windowShowing(cell, in: theme(named: "Red", color: .red, fontSize: 17))
        withExtendedLifetime(window) {
            XCTAssertEqual(
                cell.switchControl.onTintColor?.resolvedColor(with: cell.traitCollection),
                UIColor.red,
                "a switch inside one of our components is ours to theme — Apple's green is not in any brand's palette"
            )
        }
    }

    func testSwitchingThemeCountsAsAColorAppearanceChange() {
        let marine = UITraitCollection { $0[PinwheelThemeTrait.self] = theme(named: "Marine", color: .red, fontSize: 10) }
        let ember = UITraitCollection { $0[PinwheelThemeTrait.self] = theme(named: "Ember", color: .blue, fontSize: 10) }
        XCTAssertTrue(
            marine.hasDifferentColorAppearance(comparedTo: ember),
            "UIKit re-resolves a dynamic UIColor only for a trait that declares it changes color appearance — without it a tint stays on the theme it was assigned under"
        )
    }

    func testThemePickerStaysHiddenForASingleTheme() {
        let chrome = PinwheelChrome()
        chrome.themes = [theme(named: "Marine", color: .red, fontSize: 10)]
        XCTAssertFalse(chrome.isThemePickerVisible, "a catalog with one theme has nothing to pick between")
    }
}
