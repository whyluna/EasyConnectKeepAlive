// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EasyConnectKeepAlive",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "EasyConnectKeepAlive", targets: ["EasyConnectKeepAlive"])
    ],
    targets: [
        .executableTarget(
            name: "EasyConnectKeepAlive",
            path: "Sources"
        )
    ]
)
