# Migrating To SwiftUI-First Pinwheel

This guide is for projects moving from the UIKit-first Pinwheel API to the SwiftUI-first API.

## Build The Catalog With `PinwheelCatalog`

The SwiftUI `PinwheelCatalog` is the catalog host, and it is the only one: `PinwheelTableViewController`, the item-hosting `PinwheelViewController` / `PinwheelHostingViewController` and `PinwheelItem.viewController` have all been removed. Present it like this:

```swift
@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            PinwheelCatalog {
                PinwheelSection("Components", id: "components") {
                    PinwheelItem("Button", id: "button") { ButtonDemo() }
                }
            }
        }
    }
}
```

UIKit *content* still drops into this catalog — the `view:` and `viewController:` item initializers below are unchanged.

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

Presentation and display details read as modifiers now:

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

## Add A Subview And Constrain It In One Call

The parent adds and constrains in one call, which replaces the `fillInSuperview` family. Those sat on the *child* and looked upward for a superview, so a view that had yet to be added silently stayed unconstrained, and one already in the hierarchy spent a window with constraints still to come:

```swift
// before
addSubview(tableView)
tableView.fillInSuperview()

addSubview(stackView)
stackView.anchorToTopSafeArea(margin: .spacingL)

// after
addSubview(tableView, filling: .all)

addSubview(stackView, filling: safeAreaLayoutGuide, edges: [.top, .leading, .trailing], margin: .spacingL)
```

Edges come from UIKit's `NSDirectionalRectEdge`. Pass edges alone to pin to the parent's own bounds, or name a `UILayoutGuide` to pin to that instead:

| Before | After |
|---|---|
| `fillInSuperview(insets:)` | `addSubview(_:filling: .all, insets:)` |
| `fillInSuperview(margin:)` | `addSubview(_:filling: .all, margin:)` |
| `fillInSafeArea(insets:)` | `addSubview(_:filling: safeAreaLayoutGuide, insets:)` |
| `fillInSafeArea(margin:)` | `addSubview(_:filling: safeAreaLayoutGuide, margin:)` |
| `anchorToTopSafeArea(margin:)` | `addSubview(_:filling: safeAreaLayoutGuide, edges: [.top, .leading, .trailing], margin:)` |
| `anchorToBottomSafeArea(margin:)` | `addSubview(_:filling: safeAreaLayoutGuide, edges: [.leading, .trailing, .bottom], margin:)` |
| `fillInSuperviewWithSafeAreaTop(insets:)` | `addSubview(_:top: safeAreaLayoutGuide.topAnchor, leading: leadingAnchor, trailing: trailingAnchor, bottom: bottomAnchor, insets:)` |
| `fillInVerticalLayoutMarginsHorizontalSafeArea(insets:)` | `addSubview(_:top: layoutMarginsGuide.topAnchor, leading: safeAreaLayoutGuide.leadingAnchor, trailing: safeAreaLayoutGuide.trailingAnchor, bottom: layoutMarginsGuide.bottomAnchor, insets:)` |

The last two mixed one guide with another per edge. Pass the four anchors directly for those, which also covers pinning to a sibling or to a guide from anywhere else.

Where z-order matters, `insertSubview(_:belowSubview:filling:)` does the same for an insertion.

## Set A Cell's Selected Background Directly

`UITableViewCell.setDefaultSelectedBackgound()` is gone — it wrapped three lines and carried a misspelling
into every call site. Write them where they run:

```swift
let selectedBackgroundView = UIView()
selectedBackgroundView.backgroundColor = .secondaryBackground
cell.selectedBackgroundView = selectedBackgroundView
```
