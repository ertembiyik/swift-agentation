import ProjectDescription

let config = Config(
    compatibleXcodeVersions: .all,
    swiftVersion: "5.9",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: true
    )
)
