// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let SwiftSTLinkV3BridgePath = URL(fileURLWithPath: ".").appendingPathComponent(".build/checkouts/SwiftSTLinkV3Bridge")

let package = Package(
    name: "MonoUI",
    products: [
        .library(
            name: "MonoUI",
            targets: ["MonoUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/CmST0us/SwiftSDL2.git", branch: "main"),
        .package(url: "https://github.com/CmST0us/SwiftSTLinkV3Bridge.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MonoUI"),

        .executableTarget(
            name: "MonoUISDLSimulator",
            dependencies: [
                "MonoUI",
                .product(name: "SDL2", package: "SwiftSDL2")]),

        .executableTarget(
            name: "MonoUISTLinkV3BridgeSSD1306",
            dependencies: [
                "MonoUI",
                .product(name: "SwiftSTLinkV3Bridge", package: "SwiftSTLinkV3Bridge")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-cxx-interoperability-mode=default"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath=\(SwiftSTLinkV3BridgePath.path)/Sources/CSTSWLink007/linux_x64",
                    "-L", "\(SwiftSTLinkV3BridgePath.path)/Sources/CSTSWLink007/linux_x64",
                    "-lSTLinkUSBDriver",
                    "-lm"
                ])
            ])
    ]
)
