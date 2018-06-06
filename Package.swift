// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "Mint",
    products: [
        .executable(name: "mint", targets: ["Mint"]),
        .library(name: "MintKit", targets: ["MintKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", from: "0.9.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.1.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.2.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI", from: "5.0.0"),
    ],
    targets: [
        .target(name: "Mint", dependencies: ["MintCLI"]),
        .target(name: "MintCLI", dependencies: ["Rainbow", "SwiftCLI", "MintKit"]),
        .target(name: "MintKit", dependencies: ["Rainbow", "PathKit", "Utility", "SwiftCLI"]),
        .testTarget(name: "MintTests", dependencies: ["MintKit"]),
    ]
)
