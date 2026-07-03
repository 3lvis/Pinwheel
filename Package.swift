// swift-tools-version: 6.2
// Root manifest for external `.package(url:)` consumers; mirrors
// Pinwheel/Package.swift — keep dependencies in sync across both.

import PackageDescription

let package = Package(
    name: "Pinwheel",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Pinwheel",
            targets: ["Pinwheel"]),
    ],
    dependencies: [
        .package(path: "PinwheelMacros"),
    ],
    targets: [
        .target(
            name: "Pinwheel",
            dependencies: [
                .product(name: "PinwheelMacros", package: "PinwheelMacros"),
            ],
            path: "Pinwheel/Sources",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]),
        .testTarget(
            name: "PinwheelTests",
            dependencies: ["Pinwheel"],
            path: "Pinwheel/Tests"),
    ]
)
