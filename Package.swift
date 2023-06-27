// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Designable",
    products: [
        .library(
            name: "Designable",
            targets: ["Designable"]),
    ],
    targets: [
        .target(
            name: "Designable",
            path: "Designable/Sources"),
        .testTarget(
            name: "DesignableTests",
            dependencies: ["Designable"],
            path: "Designable/Tests"),
    ]
)
