// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SIFloatingCollection",
    products: [
        .library(
            name: "SIFloatingCollection",
            targets: ["SIFloatingCollection"]),
    ],
    targets: [
        .target(
            name: "SIFloatingCollection",
            dependencies: [],
        path: "./Sources"),
        .testTarget(
            name: "SIFloatingCollectionTests",
            dependencies: ["SIFloatingCollection"],
            path: "./Example/ExampleTests"),
    ]
)
