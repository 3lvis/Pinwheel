// swift-tools-version: 6.2
// The demo catalog's typed identifiers, shared by the Demo app and DemoUITests.
// A UI-test target can't import the app, so these names live in a module both
// depend on — one source of truth for typed authoring and typed deep-links.

import PackageDescription

let package = Package(
    name: "DemoCatalog",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(name: "DemoCatalog", targets: ["DemoCatalog"]),
    ],
    dependencies: [
        .package(path: "../Pinwheel"),
    ],
    targets: [
        .target(
            name: "DemoCatalog",
            dependencies: ["Pinwheel"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]),
    ]
)
