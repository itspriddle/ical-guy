// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ical-guy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ical-guy", targets: ["ical-guy"]),
        .library(name: "ICalGuyKit", targets: ["ICalGuyKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
        .package(url: "https://github.com/hummingbird-project/swift-mustache.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ical-guy",
            dependencies: [
                "ICalGuyKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "ICalGuyKit",
            dependencies: [
                .product(name: "TOMLKit", package: "TOMLKit"),
                .product(name: "Mustache", package: "swift-mustache")
            ]
        ),
        .testTarget(
            name: "ICalGuyKitTests",
            dependencies: ["ICalGuyKit"]
        )
    ]
)
