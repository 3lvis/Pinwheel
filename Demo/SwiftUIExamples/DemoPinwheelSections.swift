import Pinwheel

@MainActor
enum DemoPinwheelSections {
    static var dna: PinwheelSection {
        PinwheelSection("DNA", id: "dna") {
            PinwheelItem("Font", id: "font") {
                PinFontExample()
            }

            PinwheelItem("Color", id: "color") {
                PinColorExample()
            }

            PinwheelItem("Spacing", id: "spacing") {
                PinSpacingExample()
            }
        }
    }

    static var components: PinwheelSection {
        PinwheelSection("Components", id: "components") {
            PinwheelItem("Label", id: "label") {
                PinLabelExample()
            }

            PinwheelItem("Tweakable", id: "tweakable") {
                PinTweakableExample()
            }

            PinwheelItem("FullscreenView", id: "fullscreen-view") {
                PinFullscreenViewExample()
            }

            PinwheelItem("Button", id: "button") {
                PinButtonExample()
            }

            PinwheelItem("StateView", id: "state-view") {
                PinStateViewExample()
            }
        }
    }

    static var reciclable: PinwheelSection {
        PinwheelSection("Reciclable", id: "reciclable") {
            PinwheelItem("TableView", id: "table-view") {
                PinTableViewExample()
            }
            .pinwheelPresentation(.medium)
        }
    }

    static var uikit: PinwheelSection {
        PinwheelSection("UIKit", id: "uikit") {
            PinwheelItem("UIKit Font", id: "uikit-font", view: UIKitPinFontExample.self)
            PinwheelItem("UIKit Color", id: "uikit-color", view: UIKitPinColorExample.self)
            PinwheelItem("UIKit Spacing", id: "uikit-spacing", view: UIKitPinSpacingExample.self)
            PinwheelItem("UIKit Label", id: "uikit-label", view: UIKitPinLabelExample.self)
            PinwheelItem("UIKit Tweakable", id: "uikit-tweakable", view: UIKitPinTweakableExample.self)
            PinwheelItem("UIKit FullscreenView", id: "uikit-fullscreen-view", view: UIKitPinFullscreenViewExample.self)
            PinwheelItem("UIKit Button", id: "uikit-button", view: UIKitPinButtonExample.self)
            PinwheelItem("UIKit StateView", id: "uikit-state-view", view: UIKitPinStateViewExample.self)
            PinwheelItem("UIKit TableView", id: "uikit-table-view", view: UIKitPinTableViewExample.self)
                .pinwheelPresentation(.medium)
        }
    }
}
