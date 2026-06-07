// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    targets: [
        .target(
            name: "Pinwheel",
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
