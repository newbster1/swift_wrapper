// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnisightLib",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "UnisightLib",
            targets: ["UnisightLib"]
        ),
    ],
    dependencies: [
        // Temporarily removed OpenTelemetry dependency due to API compatibility issues
        // .package(url: "https://github.com/open-telemetry/opentelemetry-swift", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "UnisightLib",
            dependencies: [
                // Temporarily removed OpenTelemetry dependencies due to API compatibility issues
                // .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                // .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift"),
                // .product(name: "ResourceExtension", package: "opentelemetry-swift"),
                // .product(name: "URLSessionInstrumentation", package: "opentelemetry-swift"),
                // .product(name: "NetworkStatus", package: "opentelemetry-swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "UnisightLibTests",
            dependencies: ["UnisightLib"],
            path: "Tests"
        ),
    ]
)