import ProjectDescription

let project = Project(
    name: "AgentationExample",
    organizationName: "Agentation",
    options: .options(
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    packages: [
        .local(path: "../")
    ],
    targets: [
        // iOS App (with UIKit + SwiftUI demos)
        .target(
            name: "AgentationExample",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.agentation.example",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "LaunchScreenColor",
                    "UIImageName": ""
                ]
            ]),
            sources: [
                "Sources/MacApp/**",
                "Sources/SwiftUIDemo/**",
                "Sources/UIKitDemo/**"
            ],
            resources: ["Resources/**"],
            dependencies: [
                .package(product: "Agentation", type: .runtime)
            ]
        ),
        // macOS App (SwiftUI only)
        .target(
            name: "AgentationExampleMac",
            destinations: [.mac],
            product: .app,
            bundleId: "com.agentation.example.mac",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "LSMinimumSystemVersion": "14.0"
            ]),
            sources: ["Sources/MacApp/**", "Sources/SwiftUIDemo/**"],
            resources: ["Resources/**"],
            dependencies: [
                .package(product: "Agentation", type: .runtime)
            ]
        )
    ]
)
