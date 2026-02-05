// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Agentation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Agentation",
            targets: ["Agentation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Aeastr/UniversalGlass.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "Agentation",
            dependencies: ["UniversalGlass"],
            path: "Sources/Agentation"
        ),
        .testTarget(
            name: "AgentationTests",
            dependencies: ["Agentation"],
            path: "Tests/AgentationTests"
        ),
    ]
)
