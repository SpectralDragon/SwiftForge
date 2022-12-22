// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftForge",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "swift-forge",
            targets: ["swift-forge"]
        ),
        .library(
            name: "Forge",
            type: .dynamic,
            targets: ["Forge"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-tools-support-core", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "swift-forge",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ForgeCommands"
            ]
        ),
        .target(
            name: "ForgeCommands",
            dependencies: [
                "ForgeCore",
            ]
        ),
        .target(
            name: "ForgeRuntime",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "ForgeBuildCore"
            ]
        ),
        .target(
            name: "Forge",
            dependencies: [
                "ForgeRuntime",
                "ForgeBuildCore"
            ]
        ),
        .target(
            name: "ForgeCore",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "ForgeRuntime",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "ForgeBuildCore"
        ),
        .testTarget(
            name: "SwiftForgeTests",
            dependencies: ["swift-forge"]),
    ]
)
