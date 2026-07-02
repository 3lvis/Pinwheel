// swift-tools-version: 6.2
// Manifest used by the Demo; the root Package.swift re-exposes this for external
// `.package(url:)` consumers — keep dependencies in sync across both.

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
    dependencies: [],
    targets: [
        .target(
            name: "Pinwheel",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .defaultIsolation(MainActor.self),
            ]),
        .testTarget(
            name: "PinwheelTests",
            dependencies: ["Pinwheel"]),
    ]
)
