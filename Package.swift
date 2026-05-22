// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BoardingPassKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BoardingPassKit",
            targets: ["BoardingPassKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BoardingPassKit",
            path: "packages/swift/Sources/BoardingPassKit"),
        .testTarget(
            name: "BoardingPassKitTests",
            dependencies: ["BoardingPassKit"],
            path: "packages/swift/Tests/BoardingPassKitTests"),
    ]
)
