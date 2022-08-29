// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let anyVersion: Range<Version> = "1.0.0"..<"10.0.0"

let package = Package(
    name: "CommonApi",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CommonApi",
            targets: ["CommonApi"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/vapor/vapor.git", anyVersion),
        .package(url: "https://github.com/vapor/fluent-kit.git", anyVersion),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CommonApi",
            dependencies: [
                .product(name: "FluentKit", package: "fluent-kit"),
                .product(name: "Vapor", package: "vapor"),]),
        .testTarget(
            name: "CommonApiTests",
            dependencies: ["CommonApi"]),
    ]
)
