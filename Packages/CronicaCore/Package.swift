// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CronicaCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "CronicaCore", targets: ["CronicaCore"])
    ],
    targets: [
        .target(
            name: "CronicaCore",
            dependencies: [],
            path: "Sources/CronicaCore"
        ),
        .testTarget(
            name: "CronicaCoreTests",
            dependencies: ["CronicaCore"],
            path: "Tests/CronicaCoreTests"
        )
    ]
)
