// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mint",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "mint",
            targets: ["Mint"]),
        .library(
            name: "MintKit",
            targets: ["MintKit"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/kylef/PathKit.git", from: "0.8.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "1.2.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "2.1.0"),
        .package(url: "https://github.com/nsomar/Guaka.git", from: "0.1.3"),
        ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Mint",
            dependencies: [
                "MintKit",
                "Rainbow",
                "Guaka",
                ]),
        .target(
            name: "MintKit",
            dependencies: [
                "ShellOut",
                "Rainbow",
                "PathKit",
                ]),
        .testTarget(
            name: "MintTests",
            dependencies: ["MintKit"]),
        ]
)
