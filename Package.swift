// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUISSG",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftUISSGCore",
            targets: ["SwiftUISSGCore"]),
        .library(
            name: "SwiftUISSG",
            targets: ["SwiftUISSG"]),
        .library(name: "Example", targets: ["Example"])
    ],
    dependencies: [
        .package(url: "https://github.com/robb/Swim.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-markdown", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3"),
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.22.0")),
    ],
    targets: [
        .target(name: "SwiftUISSG", dependencies: [
            "SwiftUISSGCore",
            .product(name: "HTML", package: "Swim"),
            .product(name: "Swim", package: "Swim"),
            .product(name: "Markdown", package: "swift-markdown"),
        ]),
        .target(name: "SwiftUISSGCore", dependencies: [
            // SwiftUI
        ]),
        .target(name: "LiveReload", dependencies: [
            .product(name: "FlyingFox", package: "FlyingFox"),
        ], resources: [.copy("Resources/livereload.js")]),
        .target(name: "Example", dependencies: [
            "SwiftUISSG",
            .product(name: "Yams", package: "yams")
        ]),
        .executableTarget(name: "GUI", dependencies: [
            "LiveReload",
            "Example",
        ]),
        .testTarget(
            name: "SwiftUISSGTests",
            dependencies: ["SwiftUISSGCore", "Example"]
        ),
    ]
)
