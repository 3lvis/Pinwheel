![Pinwheel](https://github.com/3lvis/Pinwheel/blob/main/.github/cover.png?raw=true)

# Pinwheel

Pinwheel is a SwiftUI-first catalog and playground for inspecting app UI in multiple states, presentations, and device sizes. It is designed for design-system previews, component libraries, and feature teams that want a lightweight internal demo app without building navigation, device simulation, and tweak controls from scratch.

Pinwheel still supports UIKit views and view controllers, but the default API is SwiftUI.

## Requirements

- iOS 18+
- Xcode 26.5+
- Swift 6.3+
- Swift Package Manager

## Installation

Add Pinwheel in Xcode with **File > Add Package Dependencies...** and use:

```text
https://github.com/3lvis/Pinwheel
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/3lvis/Pinwheel", branch: "swiftui")
```

Then add the product to your app target:

```swift
.product(name: "Pinwheel", package: "Pinwheel")
```

## SwiftUI Quick Start

```swift
import SwiftUI
import Pinwheel

@main
struct DesignSystemDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PinwheelCatalog {
                PinwheelSection("Components") {
                    PinwheelItem("Primary Button") {
                        PrimaryButtonDemo()
                    }

                    PinwheelItem("Empty State") {
                        EmptyStateDemo()
                    }
                    .presentation(.medium)
                }
            }
        }
    }
}
```

Sections and items derive a stable id from their title — an item also folds in its `tags` (see [Tags](#tags)). Pinwheel persists the selected section, item, and simulated device by that id, so selection survives reordering. Titles must be unique within a section; two takes on the same component are disambiguated by their tags.

## Tweaks

Attach actions and toggles to any SwiftUI demo with `pinwheelTweaks`. They appear in Pinwheel's floating settings sheet.

```swift
struct PrimaryButtonDemo: View {
    @State private var isLoading = false
    @State private var isDisabled = false

    var body: some View {
        Button(isLoading ? "Saving" : "Save") {
            isLoading.toggle()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
        .pinwheelTweaks {
            PinwheelTweak("Loading", isOn: $isLoading)
            PinwheelTweak("Disabled", isOn: $isDisabled)
        }
    }
}
```

## Item Options

The primary initializer stays small:

```swift
PinwheelItem("Profile Card") {
    ProfileCardDemo()
}
```

Advanced behavior is configured with fluent modifiers:

```swift
PinwheelItem("Booking Sheet") {
    BookingSheetDemo()
}
.presentation(.medium)
.supportedInterfaceOrientations(.portrait)
.safeArea(top: true, bottom: false)
.tabletDisplayMode(.detail)
```

Available presentations:

- `.fullscreen`
- `.medium`
- `.large`

## Tags

Tag an item with the world it belongs to. Tags render as a filter of pills under the section picker, and they fold into the item's id — so the SwiftUI and UIKit takes on the same component get distinct ids without a manual one, and share one section:

```swift
PinwheelItem("Button") { PinButtonDemo() }.tags(.swiftUI)    // id "swiftui-button"
PinwheelItem("Button", view: ButtonView.self).tags(.uiKit)   // id "uikit-button"
```

## Typed component names

Titles and ids are strings by default. To make them typed and refactor-safe, declare a `String` enum conforming to `PinwheelComponent` — you get typed item creation and a matching deep-link id, with no hand-written slug:

```swift
enum Catalog: String, PinwheelComponent {
    case button = "Button"
    case stateView = "StateView"
}

PinwheelItem(Catalog.button, view: ButtonView.self).tags(.uiKit)   // id "uikit-button"
```

Put that enum in a module your app **and** its UI-test target import (a UI-test target runs in a separate process and can't import the app). Then a preview or test deep-links by deriving the id from the same enum — one source of truth, no copied slug:

```swift
app.launchArguments += ["-PinwheelPreview", Catalog.stateView.id(.uiKit)]   // "uikit-stateview"
```

## Previewing a Single Component

Every catalog item is addressable by id, so you can render one component in isolation — no hand-written `#Preview` scaffolding. The `PinwheelSection`/`PinwheelItem` registry doubles as the preview index.

In SwiftUI (including an Xcode `#Preview`):

```swift
PinwheelPreview("primary-button") {
    PinwheelSection("Components") {
        PinwheelItem("Primary Button") { PrimaryButtonDemo() }
    }
}
```

`PinwheelPreview` accepts a bare item id (`"primary-button"`) or a qualified `"sectionID/itemID"` to disambiguate ids shared across sections; an unknown id renders the list of available ids.

To deep-link the demo app straight to one component, branch the scene on `PinwheelPreview.requestedID`. It reads the `-PinwheelPreview <id>` launch argument or the `PINWHEEL_PREVIEW` environment variable:

```swift
WindowGroup {
    if let id = PinwheelPreview.requestedID {
        PinwheelPreview(id, sections: allSections)
    } else {
        PinwheelCatalog { /* ... */ }
    }
}
```

```sh
xcrun simctl launch <booted-device> com.example.app -PinwheelPreview primary-button
```

## UIKit Compatibility

UIKit views can still be shown directly:

```swift
PinwheelItem("Profile Card", view: ProfileCardView.self).tags(.uiKit)
```

UIKit view controllers can be wrapped with a factory:

```swift
PinwheelItem("Checkout", viewController: { CheckoutViewController() })
    .tags(.uiKit)
    .presentation(.large)
```

SwiftUI can also embed UIKit explicitly:

```swift
PinwheelUIKitView(view: ProfileCardView.self)
PinwheelUIKitViewController {
    CheckoutViewController()
}
```

And the reverse direction: drop a SwiftUI-first `Pin*` component into a UIKit `UIStackView` / Auto Layout hierarchy with `PinHostView`, a self-sizing `UIView` that needs no SwiftUI knowledge at the call site. Theming and light/dark/Dynamic Type propagate across the boundary:

```swift
let host = PinHostView(rootView: PinButton("Save") { save() })
stackView.addArrangedSubview(host)
```

Components that already ship a UIKit-friendly shell — `UIKitPinButton`, `UIKitPinStateView` — are thin hosts over their single SwiftUI implementation (`PinButton`, `PinStateView`), so a hybrid app keeps the imperative ergonomics (`title` / `isEnabled` / `state` mutation, target-action / delegate) it expects.

## Device Simulation

Pinwheel can preview a demo in known iPhone and iPad sizes from the floating settings sheet. SwiftUI demos receive the simulated horizontal and vertical size classes through the SwiftUI environment while the content frame is resized to the selected device.

## Demo App

The demo app groups examples by concept into three sections:

- `Tokens`
- `Components`
- `Screens`

Each component's SwiftUI and UIKit takes live in the same section, distinguished by a `SwiftUI` / `UIKit` tag rather than split into separate sections.

## Migration

Migration notes are kept out of the main README. See [MIGRATION.md](MIGRATION.md) for guidance when moving from the UIKit-first API to the SwiftUI-first API.

## Current Status

This branch is the SwiftUI-first API line. The package builds with Swift 6.3, defaults Pinwheel's target isolation to `MainActor`, and keeps UIKit compatibility for projects migrating gradually.
