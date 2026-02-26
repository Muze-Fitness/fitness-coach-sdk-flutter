// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "zing_sdk_initializer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "zing-sdk-initializer", targets: ["zing_sdk_initializer"])
    ],
    dependencies: [
        .package(url: "https://github.com/Muze-Fitness/zing-coach-sdk-ios", exact: "1.0.8")
    ],
    targets: [
        .target(
            name: "zing_sdk_initializer",
            dependencies: [
                .product(name: "ZingCoach", package: "zing-coach-sdk-ios")
            ]
        )
    ]
)
