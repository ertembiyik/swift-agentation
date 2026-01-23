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
        .target(
            name: "AgentationExample",
            destinations: [.iPhone, .iPad, .macCatalyst],
            product: .app,
            bundleId: "com.agentation.example",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "LaunchScreenColor",
                    "UIImageName": ""
                ],
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                            ]
                        ]
                    ]
                ]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .package(product: "Agentation", type: .runtime)
            ]
        )
    ]
)
