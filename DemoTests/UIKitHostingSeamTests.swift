import XCTest
import SwiftUI
import UIKit
@testable import Pinwheel

@MainActor
final class UIKitHostingSeamTests: XCTestCase {
    private final class TweakableView: UIView, Tweakable {
        static var instancesCreated = 0

        let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            Self.instancesCreated += 1
            label.text = "Nothing chosen."
            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is unused in tests") }

        var tweaks: [Tweak] {
            [TextTweak(title: "Option 1") { [weak self] in self?.label.text = "You chose Option 1." }]
        }
    }

    private final class TweakableViewController: UIViewController, Tweakable {
        let label = UILabel()

        override func viewDidLoad() {
            super.viewDidLoad()
            label.text = "Nothing chosen."
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }

        var tweaks: [Tweak] {
            [TextTweak(title: "Option 1") { [weak self] in self?.label.text = "You chose Option 1." }]
        }
    }

    private func host(_ item: PinwheelItem) -> (window: UIWindow, chrome: PinwheelChrome) {
        let chrome = PinwheelChrome()
        chrome.themes = [.standard]
        chrome.normalizeTheme()

        let playground = PinwheelPlayground(
            item: item,
            selection: PinwheelSelection(sectionID: "components", itemID: item.id),
            onClose: {},
            previewMode: true
        )
        .environment(chrome)

        return (HostedView.window(showing: playground), chrome)
    }

    func testAHostedUIKitViewIsBuiltOnceAcrossPlaygroundRerenders() throws {
        TweakableView.instancesCreated = 0
        let (window, chrome) = host(PinwheelItem("Tweakable", view: TweakableView.self))
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        for shows in [true, false, true] {
            chrome.showsTweaks = shows
            window.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertEqual(
            TweakableView.instancesCreated,
            1,
            "the view is rebuilt on every playground re-render, and a fresh one would leave the tweak controls driving a discarded copy"
        )
    }

    func testAUIKitViewsTweakDrivesTheViewTheCatalogIsShowing() throws {
        TweakableView.instancesCreated = 0
        let (window, chrome) = host(PinwheelItem("Tweakable", view: TweakableView.self))
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        chrome.showsTweaks = true
        _ = try HostedView.attachedTray(in: window)

        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Option 1", in: window),
            "a UIKit Tweakable's tweaks should bridge into the tray"
        )
        XCTAssertTrue(
            HostedView.accessibilityLabels(in: window).contains("You chose Option 1."),
            "the tweak should drive the hosted view the catalog is showing, not an off-screen copy"
        )
    }

    func testAUIKitViewControllersTweakDrivesTheControllerTheCatalogIsShowing() throws {
        let controller = TweakableViewController()
        let (window, chrome) = host(PinwheelItem(title: "Tweakable", viewController: controller))
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }

        chrome.showsTweaks = true
        _ = try HostedView.attachedTray(in: window)

        XCTAssertTrue(
            HostedView.activateFirst(labelled: "Option 1", in: window),
            "a UIKit view controller's tweaks should bridge into the tray"
        )
        XCTAssertEqual(
            controller.label.text,
            "You chose Option 1.",
            "the tweak should drive the live controller, not an off-screen copy"
        )
    }
}
