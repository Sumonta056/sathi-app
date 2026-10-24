// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sathi",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Sathi", path: "Sources/Sathi")
    ]
)
