// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MonoUI",
    products: [
        .library(
            name: "MonoUI",
            targets: ["MonoUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CmST0us/SwiftSDL2.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MonoUI"),

        .executableTarget(
            name: "MonoUISDLSimulator",
            dependencies: [
                "MonoUI",
                .product(name: "SDL2", package: "SwiftSDL2")])
    ]
)
