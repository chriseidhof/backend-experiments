// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EndpointBuilder",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EndpointBuilder",
            targets: ["EndpointBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.10.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EndpointBuilder",
            dependencies: []),
        .executableTarget(
            name: "BackendFF",
            dependencies: [
                "FlyingFox",
                "EndpointBuilder"
            ]),
        .target(
            name: "URLEncoder",
            dependencies: []),
        .testTarget(
            name: "BuilderTests",
            dependencies: ["EndpointBuilder", "URLEncoder"]),
        .testTarget(
            name: "URLEncoderTests",
            dependencies: ["URLEncoder"]),
    ]
)
