// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnisightSampleApp",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .executable(
            name: "UnisightSampleApp",
            targets: ["UnisightSampleApp"]
        )
    ],
    dependencies: [
        .package(path: "../unisight_lib")
    ],
    targets: [
        .executableTarget(
            name: "UnisightSampleApp",
            dependencies: ["UnisightLib"],
            path: "UnisightSampleApp"
        )
    ]
)