// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Mint",
    products: [
        .executable(name: "mint", targets: ["Mint"]),
        .library(name: "MintKit", targets: ["MintKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.1.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", from: "6.0.3"),
        .package(url: "https://github.com/mxcl/Version.git", from: "1.1.0")
    ],
    targets: [
        .target(name: "Mint", dependencies: ["MintCLI"]),
        .target(name: "MintCLI", dependencies: ["Rainbow", "SwiftCLI", "MintKit"]),
        .target(name: "MintKit", dependencies: ["Rainbow", "PathKit", "Version", "SwiftCLI"]),
        .testTarget(name: "MintTests", dependencies: ["MintKit"]),
    ]
)
