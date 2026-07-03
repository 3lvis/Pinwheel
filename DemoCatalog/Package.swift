// swift-tools-version: 6.2

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
