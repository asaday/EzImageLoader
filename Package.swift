// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EzImageLoader",
    platforms: [
        .macOS(.v10_11), .iOS(.v9), .tvOS(.v9), .watchOS(.v2),
    ],
    products: [
        .library(name: "EzImageLoader", targets: ["EzImageLoader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/asaday/EzHTTP.git", from: "3.6.0"),
    ],
    targets: [
        .target(
            name: "EzImageLoader",
            dependencies: ["EzHTTP", "webp"]
        ),

        .target(
            name: "webp",
            dependencies: ["libwebp"],
            path: ".",
            sources: ["webp"],
            publicHeadersPath: "webp"
        ),

        .target(
            name: "libwebp",
            path: ".",
            sources: ["libwebp/src"],
            publicHeadersPath: "libwebp/src/webp",
            cSettings: [.headerSearchPath("libwebp")]
        ),
    ]
)
