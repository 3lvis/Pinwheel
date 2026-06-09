# Migrating To SwiftUI-First Pinwheel

This guide is for projects moving from the UIKit-first Pinwheel API to the SwiftUI-first API.

## Prefer SwiftUI Items

Old UIKit items still work:

```swift
PinwheelItem("Button", id: "uikit-button", view: ButtonDemoView.self)
```

New items should prefer SwiftUI content closures:

```swift
PinwheelItem("Button", id: "button") {
    ButtonDemo()
}
```

## Move Presentation Options To Modifiers

Initializer arguments for presentation and display details are no longer the preferred style. Use modifiers instead:

```swift
PinwheelItem("Table", id: "table") {
    TableDemo()
}
.presentation(.medium)
.tabletDisplayMode(.detail)
```

## Move Safe-Area And Orientation Options To Modifiers

```swift
PinwheelItem("Fullscreen Form", id: "fullscreen-form") {
    FullscreenFormDemo()
}
.safeArea(top: false, bottom: false)
.supportedInterfaceOrientations(.portrait)
```

## Keep UIKit Demos During Transition

The demo app keeps UIKit examples in a dedicated `UIKit` section. That is the recommended migration pattern for existing apps:

```swift
PinwheelSection("UIKit", id: "uikit") {
    PinwheelItem("UIKit Button", id: "uikit-button", view: ButtonDemoView.self)
}
```

Add new native examples to their real product sections:

```swift
PinwheelSection("Components", id: "components") {
    PinwheelItem("Button", id: "button") {
        ButtonDemo()
    }
}
```

## Use Stable IDs

Pinwheel persists selected section, item, and device state by ID. Pass explicit IDs for every section and item before renaming or reordering examples.
