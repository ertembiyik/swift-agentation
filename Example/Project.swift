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
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "LaunchScreenColor",
                    "UIImageName": ""
                ]
            ]),
            sources: [
                "Sources/**",
            ],
            resources: ["Resources/**"],
            dependencies: [
                .package(product: "Agentation", type: .runtime)
            ]
        )
    ]
)
