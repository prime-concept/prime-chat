// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ChatSDK",
            targets: ["ChatSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KimIlKyum/SwiftTryCatchSPM.git", from: "1.0.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "5.11.0"),
    ],
    targets: [
        .target(
            name: "ChatSDK",
            dependencies: [
                "SwiftTryCatchSPM",
                "Starscream",
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources"
            
        ),
        .testTarget(
            name: "chatTests",
            dependencies: ["ChatSDK"],
            path: "Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
