import Pinwheel

@MainActor
enum DemoPinwheelSections {
    static var dna: PinwheelSection {
        PinwheelSection("DNA", id: "dna") {
            PinwheelItem("Font", id: "font") {
                PinSwiftUIFont()
            }

            PinwheelItem("Color", id: "color") {
                PinSwiftUIColor()
            }

            PinwheelItem("Spacing", id: "spacing") {
                PinSwiftUISpacing()
            }
        }
    }

    static var components: PinwheelSection {
        PinwheelSection("Components", id: "components") {
            PinwheelItem("Label", id: "label") {
                PinSwiftUILabel()
            }

            PinwheelItem("Tweakable", id: "tweakable") {
                PinSwiftUITweakable()
            }

            PinwheelItem("FullscreenView", id: "fullscreen-view") {
                PinSwiftUIFullscreenView()
            }

            PinwheelItem("Button", id: "button") {
                PinButtonExample()
            }

            PinwheelItem("StateView", id: "state-view") {
                PinSwiftUIStateView()
            }
        }
    }

    static var reciclable: PinwheelSection {
        PinwheelSection("Reciclable", id: "reciclable") {
            PinwheelItem("TableView", id: "table-view") {
                PinSwiftUITableView()
            }
            .pinwheelPresentation(.medium)
        }
    }

    static var uikit: PinwheelSection {
        PinwheelSection("UIKit", id: "uikit") {
            PinwheelItem("UIKit Font", id: "uikit-font", view: PinFont.self)
            PinwheelItem("UIKit Color", id: "uikit-color", view: PinColor.self)
            PinwheelItem("UIKit Spacing", id: "uikit-spacing", view: PinSpacing.self)
            PinwheelItem("UIKit Label", id: "uikit-label", view: PinLabel.self)
            PinwheelItem("UIKit Tweakable", id: "uikit-tweakable", view: PinTweakable.self)
            PinwheelItem("UIKit FullscreenView", id: "uikit-fullscreen-view", view: PinFullscreenView.self)
            PinwheelItem("UIKit Button", id: "uikit-button", view: UIKitPinButtonExample.self)
            PinwheelItem("UIKit StateView", id: "uikit-state-view", view: PinStateView.self)
            PinwheelItem("UIKit TableView", id: "uikit-table-view", view: PinTableView.self)
                .pinwheelPresentation(.medium)
        }
    }
}
