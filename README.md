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

## Theming

Every Pinwheel surface resolves its colors and fonts from a `PinwheelTheme` — a named pairing of a
`PinwheelColorProvider` and a `PinwheelFontProvider`. Supply your own and the catalog, the floating controls, and every
`Pin*` component render in it:

```swift
extension PinwheelTheme {
    static let marine = PinwheelTheme(name: "Marine", colors: MarineColors(), fonts: MarineFonts())
}

PinwheelCatalog(themes: [.marine]) {
    PinwheelSection("Components") { /* ... */ }
}
```

A builder takes a list wherever it takes a literal, so sections you already hold in one place — the same
array `PinwheelPreview(sections:)` takes — stay in one place:

```swift
PinwheelCatalog(themes: [.marine]) {
    MyCatalog.sections
}
```

Hand it more than one and a Theme control appears in the bottom bar, so a design system with
several brands switches between them live — including while a component is open. The choice persists across
launches, and falls back to the first theme when a persisted name is gone.

```swift
PinwheelCatalog(themes: [.marine, .ember]) { /* ... */ }
```

The theme reaches UIKit as well as SwiftUI: it is an `EnvironmentValues.pinwheelTheme` bridged to a
`PinwheelThemeTrait`, so a `UIColor` token resolves the selected theme wherever it is read — including
inside a `PinwheelItem(_:view:)` and inside the floating-controls window, which sits outside the SwiftUI
tree. `UIFont` has no dynamic counterpart, so a UIKit view that caches a font re-reads it on a
trait change. The window takes the theme's `actionText` as its `tintColor` as well, so the chrome
the system presents for you — a `UIAlertController` and its kind, which read no trait of ours —
comes out in the brand with no tinting code of your own.

A theme also decides its buttons' silhouette, since that is a brand's signature as much as its palette:

```swift
PinwheelTheme(name: "Ember", colors: EmberColors(), fonts: EmberFonts(), buttonShape: .capsule)
```

`buttonShape` is `.rounded` unless you say otherwise. A capsule is half the button's height rather than a
fixed radius, so it stays a shape rather than collapsing to a `CGFloat`.

Omit `themes:` and everything resolves `PinwheelTheme.standard`, which wraps Apple's system colors and fonts.

## Trays

A tray is a short, focused surface that stands as tall as its own content. Present a sequence of them
with `pinwheelTray(path:)` — the array is the stack, so appending pushes and removing pops.

```swift
struct BoostView: View {
    private enum Destination: Hashable { case boost, howItWorks }

    @State private var path: [Destination] = []

    var body: some View {
        PinButton("Boost Post") { path = [.boost] }
            .pinwheelTray(path: $path) { destination in
                switch destination {
                case .boost:
                    PinTray("Boost Post") {
                        TierWheel()
                        PinTraySection {
                            PinTrayValue("Region", value: region) { path.append(.region) }
                            PinTrayValue("Pay with", value: card) { path.append(.payment) }
                        }
                    }
                    .titleAccessory {
                        Button { path.append(.howItWorks) } label: { Image(systemName: "questionmark.circle") }
                    }
                    .commit("Boost Post") { path.removeAll() }

                case .howItWorks:
                    PinTray("How it works") { PinTrayText("Boosting shows your post to more people.") }
                        .commit("Got It") { path.removeLast() }
                }
            }
    }
}
```

Each tray carries a centred title and one leading control, which the stack derives: a cross at the root
that dismisses, a back chevron once pushed that pops. `.titleAccessory { }` adds a trailing control, and
`.commit(_:action:)` a button that ends the flow — leave it off where a tap already takes effect.

A tray stands as tall as it holds; `.detent(.filling)` makes it take all the room instead, for a surface
you browse rather than read. `.floating { }` stands something over the body at the tray's bottom edge —
a `PinTraySearchField`, a filter bar — and the body keeps room below its last row to be read past it.

Rows come from a small vocabulary, and the container owns the space around them: a tray separates its
sections, a `PinTraySection` separates the items within one, and a row only decides what happens inside
itself.

| | |
|---|---|
| `PinTraySection` | a run of items that belong together |
| `PinTrayValue` | what is chosen, and opens the tray that changes it |
| `PinTrayChoice` | one of a set of mutually exclusive options |
| `PinTrayText` | a paragraph, `.centred()` when it is a caption |
| `PinTrayLink` | a sentence ending in a phrase that leaves the app |
| `PinTraySearchField` | the field a search tray floats over its results |

Moving between trays springs the height and cross-dissolves the content in place as one motion, so a
sequence reads as one surface changing rather than a stack of separate sheets. A commit button standing
in both trays holds still through the move while its label changes. The tray is dismissed by its cross,
by a downward drag, or by tapping outside it; a tray that raises the keyboard stands on it and leaves
beside it on the keyboard's own clock.

## Tweaks

Attach commands, switches and choices to any SwiftUI demo with `pinwheelTweaks`. They appear in the tray behind the wrench.

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

Tag an item with an axis it belongs to. Tags render as a filter of pills under the section picker, and they fold into the item's id — so the SwiftUI and UIKit takes on the same component get distinct ids without a manual one, and share one section. SwiftUI is the default, so only the take that departs from it carries a tag:

```swift
PinwheelItem("Button") { PinButtonDemo() }                   // id "button"
PinwheelItem("Button", view: ButtonView.self).tags(.uiKit)   // id "uikit-button"
```

A pill appears for a tag that tells items apart — a lone `UIKit` pill in a section of otherwise untagged items filters down to the UIKit takes, and a tag every item carries earns no pill.

`PinTag` is open — the library ships `.swiftUI`/`.uiKit`, and you add your own axis with a static extension:

```swift
extension PinTag { static let figma = PinTag(rawValue: "Figma") }
PinwheelItem("Apple Controls") { AppleControlsDemo() }.tags(.figma)   // id "figma-apple-controls"
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

Add `-PinwheelPreviewTheme <name>` to land that preview in a specific theme, which is how a sweep captures
one component across every brand.

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

Components that already ship a UIKit-friendly shell — `UIPinButton`, `UIPinStateView` — are thin hosts over their single SwiftUI implementation (`PinButton`, `PinStateView`), so a hybrid app keeps the imperative ergonomics (`title` / `isEnabled` / `state` mutation, target-action / delegate) it expects.

## Device Simulation

Pinwheel can preview a demo in known iPhone sizes from the device list in the tweaks tray. SwiftUI demos receive the simulated horizontal and vertical size classes through the SwiftUI environment while the content frame is resized to the selected device.

## Figma Capture

Pinwheel can export your running catalog to editable Figma — every component captured 1:1 with the simulator, in light and dark, as real text/color/number nodes (not a flat screenshot). Components capture with **zero cooperation**: there's no capture code or markers in your views. The engine reads what a component renders (its structure from geometry, its names from reflection) and value-matches the rendered colors, spacing, radii, and fonts against your registered tokens so they import as named, editable Figma variables.

Register your design tokens once so the match can happen:

```swift
import Pinwheel

PinCaptureTokens.current = PinCaptureTokens(
    colors: [
        .init(name: "primaryText", light: .black, dark: .white),
        .init(name: "primaryBackground", light: .white, dark: .black),
    ],
    spacings: [.init(name: "spacing-m", value: 16)],
    radii: [.init(name: "radius-m", value: 12)],
    systemFontFamily: "SF Pro",
    textStyles: [.init(name: "body", family: "SF Pro", size: 17, weight: 400)]
)
```

Build capturable screens as eager SwiftUI (`ScrollView { VStack { ForEach } }`) — including bespoke 2-D rows (a thumbnail, a stacked text column, a trailing control), which capture with their real nested layout, not a flattened one. A `List` is UIKit-backed and captures lazily; route lists through `PinList` for a full capture. The capture flow itself (the sweep script, the local serve, and the "Pinwheel Capture Import" Figma plugin) is a developer tool that lives in the repo, not something your app links against.

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
