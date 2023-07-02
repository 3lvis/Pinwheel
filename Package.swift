// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pinwheel",
    products: [
        .library(
            name: "Pinwheel",
            targets: ["Pinwheel"]),
    ],
    targets: [
        .target(
            name: "Pinwheel",
            path: "Pinwheel/Sources"),
        .testTarget(
            name: "PinwheelTests",
            dependencies: ["Pinwheel"],
            path: "Pinwheel/Tests"),
    ]
)
