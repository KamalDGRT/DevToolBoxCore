// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DevToolBoxCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "DevToolBoxCore", targets: ["DevToolBoxCore"])
    ],
    targets: [
        .target(name: "DevToolBoxCore"),
        .testTarget(
            name: "DevToolBoxCoreTests",
            dependencies: ["DevToolBoxCore"]
        )
    ]
)
