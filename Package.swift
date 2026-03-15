// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Idler",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Idler")
    ]
)
